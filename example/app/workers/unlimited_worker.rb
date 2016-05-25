class UnlimitedWorker

  include Sidekiq::Worker
  sidekiq_options queue: 'unlimited', retry: 0

  def perform
    sleep Random.rand(11) 
  end
end
