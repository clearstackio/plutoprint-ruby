require "plutoprint/rack/middleware"

module Plutoprint
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "plutoprint.middleware" do |app|
        app.middleware.use Plutoprint::Rack::Middleware
      end
    end
  end
end
