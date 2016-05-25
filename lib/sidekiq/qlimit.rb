# frozen_string_literal: true
# 3rd party
require "sidekiq"

# internal
require "sidekiq/version"
require_relative "qlimit/qlimit_fetch"
require_relative 'qlimit/web'


# @see https://github.com/mperham/sidekiq/
module Sidekiq
  # Sidekiq per queue 'soft' limiting
  #
  # Just add somewhere in your bootstrap (config/initializers/sidekiq-qlimit.rb):
  #
  #     require "sidekiq/qlimit"
  #     Sidekiq::Qlimit.setup!
  #
  module Qlimit
    class << self
      # Hooks Qlimit into sidekiq.
      # @return [void]
      def setup!
        Sidekiq.configure_server do |config|
          require "sidekiq/qlimit/qlimit_fetch"
          Sidekiq.options[:fetch] = Sidekiq::Qlimit::QlimitFetch
        end
      end
    end
  end
end
