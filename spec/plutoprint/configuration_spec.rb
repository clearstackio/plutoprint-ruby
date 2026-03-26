require "spec_helper"

RSpec.describe Plutoprint::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "has empty options hash" do
      expect(config.options).to eq({})
    end

    it "enables PDF middleware by default" do
      expect(config.use_pdf_middleware).to be true
    end

    it "disables PNG middleware by default" do
      expect(config.use_png_middleware).to be false
    end

    it "has nil ignore_path" do
      expect(config.ignore_path).to be_nil
    end

    it "has nil ignore_request" do
      expect(config.ignore_request).to be_nil
    end

    it "has nil root_url" do
      expect(config.root_url).to be_nil
    end
  end

  describe "accessors" do
    it "allows setting options" do
      config.options = {size: :letter}
      expect(config.options).to eq({size: :letter})
    end

    it "allows setting use_pdf_middleware" do
      config.use_pdf_middleware = false
      expect(config.use_pdf_middleware).to be false
    end

    it "allows setting ignore_path as string" do
      config.ignore_path = "/admin"
      expect(config.ignore_path).to eq("/admin")
    end

    it "allows setting ignore_path as regexp" do
      config.ignore_path = /\/api\//
      expect(config.ignore_path).to eq(/\/api\//)
    end

    it "allows setting ignore_request as proc" do
      proc = ->(req) { req.path.start_with?("/skip") }
      config.ignore_request = proc
      expect(config.ignore_request).to eq(proc)
    end

    it "allows setting root_url" do
      config.root_url = "http://localhost:3000/"
      expect(config.root_url).to eq("http://localhost:3000/")
    end
  end
end

RSpec.describe Plutoprint do
  after { Plutoprint.instance_variable_set(:@configuration, nil) }

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Plutoprint.configuration).to be_a(Plutoprint::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(Plutoprint.configuration).to equal(Plutoprint.configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration instance" do
      Plutoprint.configure do |config|
        expect(config).to be_a(Plutoprint::Configuration)
      end
    end

    it "allows setting options via block" do
      Plutoprint.configure do |config|
        config.options = {size: :a4}
      end
      expect(Plutoprint.configuration.options).to eq({size: :a4})
    end
  end

  describe ".set_options" do
    it "sets plutoprint.options in request env" do
      env = {}
      request = double("request", env: env)
      Plutoprint.set_options(request, size: :legal, margins: {top: "0.5in"})
      expect(env["plutoprint.options"]).to eq({size: :legal, margins: {top: "0.5in"}})
    end
  end
end
