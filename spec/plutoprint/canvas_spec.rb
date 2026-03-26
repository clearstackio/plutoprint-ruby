require "spec_helper"
require "tmpdir"

RSpec.describe Plutoprint::Canvas do
  describe "transformation methods" do
    let(:canvas) { Plutoprint::ImageCanvas.new(100, 100) }

    after { canvas.finish }

    it "responds to translate" do
      expect(canvas).to respond_to(:translate)
    end

    it "responds to scale" do
      expect(canvas).to respond_to(:scale)
    end

    it "responds to rotate" do
      expect(canvas).to respond_to(:rotate)
    end

    it "responds to transform" do
      expect(canvas).to respond_to(:transform)
    end

    it "responds to set_matrix" do
      expect(canvas).to respond_to(:set_matrix)
    end

    it "responds to reset_matrix" do
      expect(canvas).to respond_to(:reset_matrix)
    end

    it "responds to clip_rect" do
      expect(canvas).to respond_to(:clip_rect)
    end

    it "responds to clear_surface" do
      expect(canvas).to respond_to(:clear_surface)
    end

    it "responds to save_state and restore_state" do
      expect(canvas).to respond_to(:save_state)
      expect(canvas).to respond_to(:restore_state)
    end

    it "responds to flush and finish" do
      expect(canvas).to respond_to(:flush)
      expect(canvas).to respond_to(:finish)
    end

    it "chains transformation calls" do
      result = canvas.translate(10, 20)
      expect(result).to eq(canvas)
    end
  end
end

RSpec.describe Plutoprint::ImageCanvas do
  describe ".new" do
    it "creates an image canvas with width and height" do
      canvas = described_class.new(200, 150)
      expect(canvas.width).to eq(200)
      expect(canvas.height).to eq(150)
      canvas.finish
    end

    it "creates an image canvas with format" do
      canvas = described_class.new(100, 100, Plutoprint::IMAGE_FORMAT_ARGB32)
      expect(canvas.format).to eq(Plutoprint::IMAGE_FORMAT_ARGB32)
      canvas.finish
    end

    it "defaults to ARGB32 format" do
      canvas = described_class.new(100, 100)
      expect(canvas.format).to eq(Plutoprint::IMAGE_FORMAT_ARGB32)
      canvas.finish
    end
  end

  describe "#stride" do
    it "returns the stride of the image" do
      canvas = described_class.new(100, 100)
      expect(canvas.stride).to be > 0
      canvas.finish
    end
  end

  describe "#data" do
    it "returns image data as a string" do
      canvas = described_class.new(10, 10)
      data = canvas.data
      expect(data).to be_a(String)
      expect(data.bytesize).to eq(canvas.height * canvas.stride)
      canvas.finish
    end
  end

  describe "#write_to_png" do
    it "writes image to a PNG file" do
      canvas = described_class.new(100, 100)
      canvas.clear_surface(1.0, 0.0, 0.0)
      path = File.join(Dir.tmpdir, "plutoprint_test_canvas.png")
      canvas.write_to_png(path)
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
      canvas.finish
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#write_to_png_stream" do
    it "writes image to an IO stream" do
      canvas = described_class.new(50, 50)
      canvas.clear_surface(0.0, 1.0, 0.0)
      io = StringIO.new
      canvas.write_to_png_stream(io)
      expect(io.string.bytesize).to be > 0
      canvas.finish
    end
  end

  describe ".open" do
    it "yields a canvas and calls finish automatically" do
      canvas_ref = nil
      described_class.open(50, 50) do |canvas|
        canvas_ref = canvas
        expect(canvas).to be_a(described_class)
        expect(canvas.width).to eq(50)
      end
      expect { canvas_ref.width }.to raise_error(Plutoprint::Error)
    end

    it "resolves format symbol" do
      described_class.open(50, 50, format: :argb32) do |canvas|
        expect(canvas.format).to eq(Plutoprint::IMAGE_FORMAT_ARGB32)
      end
    end

    it "calls finish even when block raises" do
      canvas_ref = nil
      begin
        described_class.open(50, 50) do |canvas|
          canvas_ref = canvas
          raise "test error"
        end
      rescue RuntimeError
        nil
      end
      expect { canvas_ref.width }.to raise_error(Plutoprint::Error)
    end
  end

  describe "#finish" do
    it "prevents further operations after finish" do
      canvas = described_class.new(10, 10)
      canvas.finish
      expect { canvas.width }.to raise_error(Plutoprint::Error)
    end
  end
end

RSpec.describe Plutoprint::PDFCanvas do
  describe ".new" do
    it "creates a PDF canvas with path and size" do
      path = File.join(Dir.tmpdir, "plutoprint_test_canvas.pdf")
      canvas = described_class.new(path, Plutoprint::PAGE_SIZE_A4)
      expect(canvas).to be_a(described_class)
      canvas.finish
      expect(File.exist?(path)).to be true
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#show_page" do
    it "finalizes current page and starts new one" do
      path = File.join(Dir.tmpdir, "plutoprint_test_canvas_pages.pdf")
      canvas = described_class.new(path, Plutoprint::PAGE_SIZE_A4)
      canvas.show_page
      canvas.show_page
      canvas.finish
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
      File.delete(path) if File.exist?(path)
    end
  end

  describe ".create_for_stream" do
    it "creates a PDF canvas writing to an IO stream" do
      io = StringIO.new
      canvas = described_class.create_for_stream(io, Plutoprint::PAGE_SIZE_A4)
      canvas.show_page
      canvas.finish
      expect(io.string.bytesize).to be > 0
    end
  end

  describe ".open" do
    it "yields a canvas and calls finish automatically" do
      path = File.join(Dir.tmpdir, "plutoprint_test_open.pdf")
      described_class.open(path, Plutoprint::PAGE_SIZE_A4) do |canvas|
        expect(canvas).to be_a(described_class)
        canvas.show_page
      end
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
      File.delete(path) if File.exist?(path)
    end

    it "resolves size symbol" do
      path = File.join(Dir.tmpdir, "plutoprint_test_open_sym.pdf")
      described_class.open(path, :letter) do |canvas|
        canvas.show_page
      end
      expect(File.exist?(path)).to be true
      File.delete(path) if File.exist?(path)
    end
  end

  describe ".open_stream" do
    it "yields a canvas writing to IO and calls finish" do
      io = StringIO.new
      described_class.open_stream(io, :a4) do |canvas|
        canvas.show_page
      end
      expect(io.string.bytesize).to be > 0
    end
  end

  describe "#set_metadata" do
    it "sets PDF metadata" do
      path = File.join(Dir.tmpdir, "plutoprint_test_canvas_meta.pdf")
      canvas = described_class.new(path, Plutoprint::PAGE_SIZE_A4)
      canvas.set_metadata(Plutoprint::PDF_METADATA_TITLE, "Test Title")
      canvas.finish
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#set_size" do
    it "changes the PDF page size" do
      path = File.join(Dir.tmpdir, "plutoprint_test_canvas_resize.pdf")
      canvas = described_class.new(path, Plutoprint::PAGE_SIZE_A4)
      canvas.set_size(Plutoprint::PAGE_SIZE_LETTER)
      canvas.show_page
      canvas.finish
      File.delete(path) if File.exist?(path)
    end
  end
end
