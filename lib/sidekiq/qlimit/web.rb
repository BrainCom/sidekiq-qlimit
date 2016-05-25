# frozen_string_literal: true
# stdlib
require "pathname"

# 3rd party
require "sidekiq"
require "sidekiq/web"

# internal
require "sidekiq/qlimit/web_extension"


if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Qlimit::WebExtension

  if Sidekiq::Web.tabs.is_a?(Array)
    # For sidekiq < 2.5
    Sidekiq::Web.tabs << "cron"
  else
    Sidekiq::Web.tabs["Qlimit"] = "qlimit"
  end
end
