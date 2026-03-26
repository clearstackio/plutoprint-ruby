require "spec_helper"
require "tmpdir"

RSpec.describe Plutoprint::Book do
  describe ".new" do
    context "with positional arguments" do
      it "creates a book with default parameters" do
        book = described_class.new
        expect(book).to be_a(described_class)
      end

      it "creates a book with custom page size" do
        book = described_class.new(Plutoprint::PAGE_SIZE_LETTER)
        size = book.page_size
        expect(size.width).to eq(Plutoprint::PAGE_SIZE_LETTER.width)
        expect(size.height).to eq(Plutoprint::PAGE_SIZE_LETTER.height)
      end

      it "creates a book with custom page size and margins" do
        book = described_class.new(Plutoprint::PAGE_SIZE_A4, Plutoprint::PAGE_MARGINS_NARROW)
        margins = book.page_margins
        expect(margins.top).to eq(Plutoprint::PAGE_MARGINS_NARROW.top)
      end

      it "creates a book with custom media type" do
        book = described_class.new(Plutoprint::PAGE_SIZE_A4, Plutoprint::PAGE_MARGINS_NORMAL, Plutoprint::MEDIA_TYPE_SCREEN)
        expect(book.media_type).to eq(Plutoprint::MEDIA_TYPE_SCREEN)
      end
    end

    context "with keyword arguments" do
      it "resolves size symbol" do
        book = described_class.new(size: :letter)
        expect(book.page_size.width).to eq(Plutoprint::PAGE_SIZE_LETTER.width)
        expect(book.page_size.height).to eq(Plutoprint::PAGE_SIZE_LETTER.height)
      end

      it "resolves margins symbol" do
        book = described_class.new(margins: :wide)
        expect(book.page_margins.top).to eq(Plutoprint::PAGE_MARGINS_WIDE.top)
        expect(book.page_margins.right).to eq(Plutoprint::PAGE_MARGINS_WIDE.right)
      end

      it "resolves media symbol" do
        book = described_class.new(media: :screen)
        expect(book.media_type).to eq(Plutoprint::MEDIA_TYPE_SCREEN)
      end

      it "uses defaults when keywords omitted" do
        book = described_class.new(size: :a5)
        expect(book.page_margins.top).to eq(Plutoprint::PAGE_MARGINS_NORMAL.top)
        expect(book.media_type).to eq(Plutoprint::MEDIA_TYPE_PRINT)
      end

      it "accepts all keywords together" do
        book = described_class.new(size: :legal, margins: :narrow, media: :screen)
        expect(book.page_size.width).to eq(Plutoprint::PAGE_SIZE_LEGAL.width)
        expect(book.page_margins.top).to eq(Plutoprint::PAGE_MARGINS_NARROW.top)
        expect(book.media_type).to eq(Plutoprint::MEDIA_TYPE_SCREEN)
      end
    end
  end

  describe "default parameters" do
    let(:book) { described_class.new }

    it "defaults to A4 page size" do
      size = book.page_size
      expect(size.width).to eq(Plutoprint::PAGE_SIZE_A4.width)
      expect(size.height).to eq(Plutoprint::PAGE_SIZE_A4.height)
    end

    it "defaults to NORMAL margins" do
      margins = book.page_margins
      expect(margins.top).to eq(Plutoprint::PAGE_MARGINS_NORMAL.top)
    end

    it "defaults to PRINT media type" do
      expect(book.media_type).to eq(Plutoprint::MEDIA_TYPE_PRINT)
    end
  end

  describe "#load_html" do
    let(:book) { described_class.new }

    it "loads HTML content" do
      book.load_html("<html><body><p>Hello</p></body></html>")
      expect(book.page_count).to be >= 1
    end

    it "loads HTML with user style" do
      book.load_html("<html><body><p>Hello</p></body></html>", "body { color: red; }")
      expect(book.page_count).to be >= 1
    end
  end

  describe "#page_count" do
    it "returns 0 before loading content" do
      book = described_class.new
      expect(book.page_count).to eq(0)
    end

    it "returns at least 1 after loading content" do
      book = described_class.new
      book.load_html("<html><body><p>Test</p></body></html>")
      expect(book.page_count).to be >= 1
    end
  end

  describe "#clear_content" do
    it "resets page count to 0" do
      book = described_class.new
      book.load_html("<html><body><p>Test</p></body></html>")
      expect(book.page_count).to be >= 1
      book.clear_content
      expect(book.page_count).to eq(0)
    end
  end

  describe "metadata" do
    let(:book) { described_class.new }

    it "sets and gets metadata with integer constants" do
      book.set_metadata(Plutoprint::PDF_METADATA_TITLE, "My Title")
      expect(book.metadata(Plutoprint::PDF_METADATA_TITLE)).to eq("My Title")
    end

    it "sets and gets metadata with symbol keys" do
      book.set_metadata(:title, "Symbol Title")
      expect(book.metadata(:title)).to eq("Symbol Title")
    end

    it "sets author with symbol key" do
      book.set_metadata(:author, "Test Author")
      expect(book.metadata(:author)).to eq("Test Author")
    end

    it "reads symbol key after setting with integer constant" do
      book.set_metadata(Plutoprint::PDF_METADATA_SUBJECT, "Test Subject")
      expect(book.metadata(:subject)).to eq("Test Subject")
    end
  end

  describe "#write_to_pdf" do
    it "writes document to PDF file" do
      book = described_class.new
      book.load_html("<html><body><h1>PDF Test</h1></body></html>")
      path = File.join(Dir.tmpdir, "plutoprint_test_book.pdf")
      book.write_to_pdf(path)
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#write_to_pdf_stream" do
    it "writes document to PDF stream" do
      book = described_class.new
      book.load_html("<html><body><h1>Stream Test</h1></body></html>")
      io = StringIO.new
      book.write_to_pdf_stream(io)
      expect(io.string.bytesize).to be > 0
    end
  end

  describe "#write_to_png" do
    it "writes document to PNG file" do
      book = described_class.new
      book.load_html("<html><body><h1>PNG Test</h1></body></html>")
      path = File.join(Dir.tmpdir, "plutoprint_test_book.png")
      book.write_to_png(path)
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
      File.delete(path) if File.exist?(path)
    end

    it "writes document to PNG with custom dimensions" do
      book = described_class.new
      book.load_html("<html><body><h1>PNG Test</h1></body></html>")
      path = File.join(Dir.tmpdir, "plutoprint_test_book_sized.png")
      book.write_to_png(path, 400, 300)
      expect(File.exist?(path)).to be true
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#write_to_png_stream" do
    it "writes document to PNG stream" do
      book = described_class.new
      book.load_html("<html><body><h1>PNG Stream</h1></body></html>")
      io = StringIO.new
      book.write_to_png_stream(io)
      expect(io.string.bytesize).to be > 0
    end
  end

  describe "#render_page" do
    it "renders a page to an image canvas" do
      book = described_class.new
      book.load_html("<html><body><p>Render test</p></body></html>")
      canvas = Plutoprint::ImageCanvas.new(200, 200)
      book.render_page(canvas, 0)
      data = canvas.data
      expect(data.bytesize).to be > 0
      canvas.finish
    end
  end

  describe "#render_document" do
    it "renders the document to an image canvas" do
      book = described_class.new
      book.load_html("<html><body><p>Doc render</p></body></html>")
      canvas = Plutoprint::ImageCanvas.new(200, 200)
      book.render_document(canvas)
      canvas.finish
    end
  end

  describe "viewport dimensions" do
    it "returns viewport width and height" do
      book = described_class.new
      expect(book.viewport_width).to be > 0
      expect(book.viewport_height).to be > 0
    end
  end

  describe "#custom_resource_fetcher" do
    it "defaults to nil" do
      book = described_class.new
      expect(book.custom_resource_fetcher).to be_nil
    end

    it "can set and get a custom resource fetcher" do
      book = described_class.new
      fetcher = Plutoprint::ResourceFetcher.new
      book.custom_resource_fetcher = fetcher
      expect(book.custom_resource_fetcher).to equal(fetcher)
    end

    it "can clear the custom resource fetcher" do
      book = described_class.new
      fetcher = Plutoprint::ResourceFetcher.new
      book.custom_resource_fetcher = fetcher
      book.custom_resource_fetcher = nil
      expect(book.custom_resource_fetcher).to be_nil
    end
  end

  describe "#page_size_at" do
    it "returns the page size at a given index" do
      book = described_class.new
      book.load_html("<html><body><p>Test</p></body></html>")
      size = book.page_size_at(0)
      expect(size).to be_a(Plutoprint::PageSize)
      expect(size.width).to be > 0
    end
  end
end
