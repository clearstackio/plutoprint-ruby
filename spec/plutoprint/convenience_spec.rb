require "spec_helper"
require "stringio"
require "tmpdir"

RSpec.describe Plutoprint do
  let(:html) { "<html><body><h1>Hello</h1></body></html>" }

  describe ".html_to_pdf" do
    it "generates a PDF file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.pdf")
        Plutoprint.html_to_pdf(html, path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
        expect(File.binread(path, 5)).to eq("%PDF-")
      end
    end

    it "writes PDF to a StringIO" do
      io = StringIO.new
      io.set_encoding("ASCII-8BIT")
      Plutoprint.html_to_pdf(html, io)
      expect(io.string.size).to be > 0
      expect(io.string[0, 5]).to eq("%PDF-")
    end

    it "accepts symbols for size and margins" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.pdf")
        Plutoprint.html_to_pdf(html, path, size: :letter, margins: :wide)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end

    it "sets metadata via keyword arguments" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.pdf")
        Plutoprint.html_to_pdf(html, path, title: "My Title", author: "Test Author")
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end
  end

  describe ".html_to_png" do
    it "generates a PNG file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.png")
        Plutoprint.html_to_png(html, path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end

    it "writes PNG to a StringIO" do
      io = StringIO.new
      io.set_encoding("ASCII-8BIT")
      Plutoprint.html_to_png(html, io)
      expect(io.string.size).to be > 0
    end
  end

  describe ".url_to_pdf" do
    it "converts a file:// URL to PDF" do
      fixture = File.expand_path("../fixtures/sample.html", __dir__)
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.pdf")
        Plutoprint.url_to_pdf("file://#{fixture}", path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end
  end

  describe ".url_to_png" do
    it "converts a file:// URL to PNG" do
      fixture = File.expand_path("../fixtures/sample.html", __dir__)
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.png")
        Plutoprint.url_to_png("file://#{fixture}", path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end
  end
end
