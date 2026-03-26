require "rails"
require "action_controller/railtie"
require "plutoprint"
require "rack/test"

# Minimal Rails app defined inline for integration testing
class PlutoprintTestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "test_secret_key_base_for_plutoprint_specs"
  config.hosts.clear # Allow all hosts in test
end

PlutoprintTestApp.initialize!

PlutoprintTestApp.routes.draw do
  get "/report" => "plutoprint_test#report"
  get "/api/data" => "plutoprint_test#api_data"
end

class PlutoprintTestController < ActionController::Base
  skip_forgery_protection

  def report
    render html: "<html><head></head><body><h1>Report</h1></body></html>".html_safe,
      layout: false
  end

  def api_data
    render json: {status: "ok"}
  end
end

RSpec.describe "Rails integration", type: :integration do
  include Rack::Test::Methods

  def app
    PlutoprintTestApp
  end

  after { Plutoprint.instance_variable_set(:@configuration, nil) }

  describe "Railtie middleware registration" do
    it "registers Plutoprint::Rack::Middleware in the middleware stack" do
      middleware_classes = PlutoprintTestApp.middleware.map(&:klass)
      expect(middleware_classes).to include(Plutoprint::Rack::Middleware)
    end
  end

  describe "PDF conversion via .pdf extension" do
    it "returns PDF content type" do
      get "/report.pdf"
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("application/pdf")
    end

    it "returns a PDF body" do
      get "/report.pdf"
      expect(last_response.body).to start_with("%PDF")
    end

    it "sets Content-Length header" do
      get "/report.pdf"
      expect(last_response.headers["content-length"].to_i).to be > 0
    end
  end

  describe "non-PDF requests pass through" do
    it "returns HTML for normal requests" do
      get "/report"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("<h1>Report</h1>")
    end

    it "returns JSON for API endpoints" do
      get "/api/data"
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("application/json")
    end
  end

  describe "PNG conversion" do
    before { Plutoprint.configure { |c| c.use_png_middleware = true } }

    it "returns PNG content type for .png requests" do
      get "/report.png"
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("image/png")
    end
  end

  describe "ignore_path" do
    before { Plutoprint.configure { |c| c.ignore_path = "/report" } }

    it "skips PDF conversion for ignored paths" do
      get "/report.pdf"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("<h1>Report</h1>")
    end
  end
end
