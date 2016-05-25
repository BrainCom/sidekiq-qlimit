class LimitedWorker

  include Sidekiq::Worker
  sidekiq_options queue: 'limited', retry: 0

  def perform
    # Typically some deathly slow worker
    puts "Limited worker start @ #{Time.now}"
    s = Random.rand(60)
    puts "Limited worker sleep #{s}"
    sleep s
    puts "Limited worker stop @ #{Time.now}"
  end
end
