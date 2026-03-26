require "spec_helper"

RSpec.describe Plutoprint::ResourceData do
  describe ".new" do
    it "creates resource data with content only" do
      rd = described_class.new("hello world")
      expect(rd.content).to eq("hello world")
    end

    it "creates resource data with content and mime type" do
      rd = described_class.new("hello", "text/plain")
      expect(rd.content).to eq("hello")
      expect(rd.mime_type).to eq("text/plain")
    end

    it "creates resource data with content, mime type, and encoding" do
      rd = described_class.new("<html></html>", "text/html", "utf-8")
      expect(rd.content).to eq("<html></html>")
      expect(rd.mime_type).to eq("text/html")
      expect(rd.text_encoding).to eq("utf-8")
    end
  end

  describe "#content" do
    it "returns frozen content string" do
      rd = described_class.new("test content")
      expect(rd.content).to be_frozen
    end

    it "returns a duplicate of the original string" do
      original = "test"
      rd = described_class.new(original)
      expect(rd.content).to eq(original)
    end
  end

  describe "#mime_type" do
    it "returns empty string when not specified" do
      rd = described_class.new("data")
      expect(rd.mime_type).to eq("")
    end
  end

  describe "#text_encoding" do
    it "returns empty string when not specified" do
      rd = described_class.new("data")
      expect(rd.text_encoding).to eq("")
    end
  end
end
