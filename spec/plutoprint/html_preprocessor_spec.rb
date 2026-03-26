require "spec_helper"

RSpec.describe Plutoprint::HTMLPreprocessor do
  describe ".process" do
    let(:root_url) { "http://localhost:3000/" }
    let(:protocol) { "https" }

    it "converts relative paths to absolute" do
      html = '<link href="/assets/app.css" rel="stylesheet">'
      result = described_class.process(html, root_url, nil)
      expect(result).to include('href="http://localhost:3000/assets/app.css"')
    end

    it "converts relative protocol URLs to absolute" do
      html = '<script src="//cdn.example.com/lib.js"></script>'
      result = described_class.process(html, nil, protocol)
      expect(result).to include('src="https://cdn.example.com/lib.js"')
    end

    it "does not modify absolute URLs" do
      html = '<link href="https://example.com/style.css">'
      result = described_class.process(html, root_url, protocol)
      expect(result).to include('href="https://example.com/style.css"')
    end

    it "handles both href and src attributes" do
      html = '<img src="/images/logo.png"><a href="/about">About</a>'
      result = described_class.process(html, root_url, nil)
      expect(result).to include('src="http://localhost:3000/images/logo.png"')
      expect(result).to include('href="http://localhost:3000/about"')
    end

    it "returns html unchanged when root_url and protocol are nil" do
      html = '<link href="/assets/app.css">'
      result = described_class.process(html, nil, nil)
      expect(result).to eq(html)
    end
  end
end
