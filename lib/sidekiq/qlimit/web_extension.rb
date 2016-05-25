require 'tilt/erubis'

module Sidekiq
  module Qlimit
    module WebExtension
      def self.registered(app)
        view_path    = File.join(File.expand_path("..", __FILE__), "views")
        app.get "/qlimit" do
            render(:erb, File.read(File.join(view_path, "index.html.erb")))
        end

        app.delete "/qlimit/:id" do |id|
          Sidekiq::Qlimit::QlimitFetch.qlimit_reset(id)
          redirect "#{root_path}qlimit"
        end
      end
    end
  end
end
