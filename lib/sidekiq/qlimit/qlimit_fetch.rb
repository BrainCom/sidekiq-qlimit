# frozen_string_literal: true

require "celluloid" if Sidekiq::VERSION < "4.0.0"
require "sidekiq"
require "sidekiq/fetch"

module Sidekiq
  module Qlimit
    # Throttled version of `Sidekiq::QlimitFetch` fetcher strategy.
    #
    #
    # Just add somewhere in your bootstrap:
    #
    #     require "sidekiq/qlimit"
    #     Sidekiq::Qlimit.setup!
    #
    # Establish max # of total workers per queue 
    #
    # sidekiq.yml 
    #
    # :qlimit:
    #   queue_name_1: 2
    #   queue_name_2: 4
    #
    class QlimitFetch < ::Sidekiq::BasicFetch
      UnitOfWork = Struct.new(:queue, :job) do
        def acknowledge
          # nothing to do
          QlimitFetch.qlimit_decrement(queue_name)
        end

        def queue_name
          queue.sub(/.*queue:/, ''.freeze)
        end

        def requeue
          Sidekiq.redis do |conn|
            conn.rpush("queue:#{queue_name}", job)
          end
        end
      end

      def initialize(options)
        super(options)
        
        # puts options
        # {:queues=>["unlimited", "limited"], :labels=>[], :concurrency=>5, :require=>".", :environment=>nil, :timeout=>8, :poll_interval_average=>nil, :average_scheduled_poll_interval=>15, :error_handlers=>[#<Sidekiq::ExceptionHandler::Logger:0x007fda0c30fe38>], :lifecycle_events=>{:startup=>[], :quiet=>[], :shutdown=>[]}, :dead_max_jobs=>10000, :dead_timeout_in_seconds=>15552000, :pidfile=>"tmp/pids/sidekiq.pid", :qlimit=>[{"limited"=>2}, {"fake"=>3}], :config_file=>"config/sidekiq.yml", :strict=>true, :fetch=>Sidekiq::Qlimit::QlimitFetch, :tag=>"example"}


        # Get our limits
        @per_queue_limits = {}
        unless options[:qlimit].nil?
          options[:qlimit].each do |limit_hash|
            limit_hash.each do |k, v|
              @per_queue_limits[k] = v
            end
          end
        end
        QlimitFetch.qlimit_script_load
      end





      def qualifying_queues
        # Working copy of @queues list
        allowed_queues = @queues.dup
        
        # Remove any queue which has hit the maximum number of concurrent jobs 
        # NOTE: Could remove a queue for which a job has just finished, but we'll catch that job on the next loop
        @per_queue_limits.each do |k, v|
              Sidekiq.logger.debug("Checking #{k} => #{v}")
              Sidekiq.redis do |conn|
                jobs_in_queue = QlimitFetch.qlimit_get(k)
                if jobs_in_queue.to_i >= v # detected a maximum concurrent case
                  allowed_queues.delete("queue:#{k}")
                  Sidekiq.logger.debug("Remove: queue:#{k}")
                end
              end
                
        end

        Sidekiq.logger.debug("Allowed Queues: #{allowed_queues}")

        # Follow original sidekiq fetch strategy
        if @strictly_ordered_queues
          allowed_queues
        else
          allowed_queues = allowed_queues.shuffle.uniq
          allowed_queues << TIMEOUT # brpop should Wait X number of seconds before returning nil
          allowed_queues
        end
      end


      def retrieve_work 
        work_text = Sidekiq.redis { |conn| conn.brpop(*qualifying_queues) }
        work = UnitOfWork.new(*work_text) if work_text

        if work.nil?
          Sidekiq.logger.debug("No Work")
          return
        end
        
        # We hack around the simultaneous zero starting problem by incrementing an expiring counter 
        okay_to_continue = QlimitFetch.qlimit_increment(work.queue_name, @per_queue_limits[work.queue_name])
        Sidekiq.logger.debug("QlimitIncrement Result => #{okay_to_continue}")

        if okay_to_continue
          Sidekiq.logger.debug("Perform #{work}")
          return work
        else
          Sidekiq.logger.debug("Requeue #{work}")
          Sidekiq.redis { |conn| conn.lpush(work.queue, work.job) }
          return nil
        end
      end

      @@qlimit_increment_sha = ""
      @@qlimit_decrement_sha = ""

      def self.qlimit_script_load
        qlimit_increment_script = <<-EOF
            local max = tonumber(ARGV[1])
            local current = tonumber(redis.call('get',KEYS[1]))
            local current_i = 0
            if nil == current then
              current_i = 0
            else
              current_i = tonumber(current)
            end

            if current_i < max then
                redis.call('incr',KEYS[1])
                redis.call('expire',KEYS[1], 14400)
                return true
            else
                return false
            end
        EOF
        qlimit_decrement_script = <<-EOF
            redis.call('decrby', KEYS[1], ARGV[1])
            local current = tonumber(redis.call('get',KEYS[1]))
            if current < 0 then
                redis.call('set',KEYS[1], 0)
            end
            redis.call('expire',KEYS[1], 14400)
        EOF

        Sidekiq.redis do |conn|
          @@qlimit_increment_sha = conn.script(:load, qlimit_increment_script)
          @@qlimit_decrement_sha = conn.script(:load, qlimit_decrement_script)
        end
      end

      def self.qlimit_hash
        qlimits = {}
        Sidekiq.redis do |conn|
          conn.scan_each(match: "qlimit:*") do |key|
            qkey = key.sub(/.*qlimit:/, ''.freeze)
            qvalue = conn.get(key)
            qvalue ||= 0
            qlimits[qkey] ||= qvalue.to_i
          end
        end
        qlimits
      end

      # return 1 if okay to continue
      # return 0 if maxed
      def self.qlimit_increment(queue, limit)
        return 1 if limit.nil?  # No limit, no processing


        Sidekiq.redis do |conn|
          result = conn.evalsha(@@qlimit_increment_sha,["qlimit:#{queue}"],[limit])
          #Sidekiq.logger.debug("Checking Qlimit #{queue} => #{result}")
          return result
        end
      end

      def self.qlimit_decrement(queue, amount = 1)
        Sidekiq.logger.debug("Qlimit Decrement: #{queue} by #{amount}")

        Sidekiq.redis do |conn|
          result = conn.evalsha(@@qlimit_decrement_sha,["qlimit:#{queue}"], [amount])
        end
      end

      def self.qlimit_reset(queue)
          self.qlimit_set(queue, 0)
      end

      # Mainly used for reset
      def self.qlimit_set(queue, amount = 0)
        Sidekiq.logger.debug("Qlimit Set: #{queue} => #{amount}")
        Sidekiq.redis do |conn|
          conn.set("qlimit:#{queue}", amount)
          conn.expire("qlimit:#{queue}", 14400)
        end
      end

      def self.qlimit_get(queue)
        Sidekiq.redis do |conn|
          result = conn.get("qlimit:#{queue}")
          return result.to_i unless result.nil?
          return 0
        end
      end

      # By leaving this as a class method, it can be pluggable and used by the Manager actor. Making it
      # an instance method will make it async to the Fetcher actor
      def self.bulk_requeue(inprogress, options)
        return if inprogress.empty?

        Sidekiq.logger.debug { "Re-queueing terminated jobs" }
        jobs_to_requeue = {}
        inprogress.each do |unit_of_work|
          jobs_to_requeue[unit_of_work.queue_name] ||= []
          jobs_to_requeue[unit_of_work.queue_name] << unit_of_work.job
        end

        Sidekiq.redis do |conn|
          conn.pipelined do
            jobs_to_requeue.each do |queue, jobs|
              conn.rpush("queue:#{queue}", jobs)
              self.qlimit_decrement(queue, jobs.length)
            end
          end
        end
        Sidekiq.logger.debug("Pushed #{inprogress.size} jobs back to Redis")
      rescue => ex
        Sidekiq.logger.warn("Failed to requeue #{inprogress.size} jobs: #{ex.message}")
      end
    end
  end
end
