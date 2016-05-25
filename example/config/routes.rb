Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  # Add sidekiq Web UI
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
