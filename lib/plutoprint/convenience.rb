module Plutoprint
  class << self
    def html_to_pdf(html, output, size: :a4, margins: :normal, media: :print, user_style: nil, user_script: nil, **metadata)
      book = Book.new(size: size, margins: margins, media: media)
      book.load_html(html, user_style || "", user_script || "")
      metadata.each { |key, value| book.set_metadata(key, value) }
      write_output(book, output, :pdf)
    end

    def html_to_png(html, output, size: :a4, margins: :normal, media: :print, width: -1, height: -1, user_style: nil, user_script: nil)
      book = Book.new(size: size, margins: margins, media: media)
      book.load_html(html, user_style || "", user_script || "")
      write_output(book, output, :png, width: width, height: height)
    end

    def url_to_pdf(url, output, size: :a4, margins: :normal, media: :print, user_style: nil, user_script: nil, **metadata)
      book = Book.new(size: size, margins: margins, media: media)
      book.load_url(url, user_style || "", user_script || "")
      metadata.each { |key, value| book.set_metadata(key, value) }
      write_output(book, output, :pdf)
    end

    def url_to_png(url, output, size: :a4, margins: :normal, media: :print, width: -1, height: -1, user_style: nil, user_script: nil)
      book = Book.new(size: size, margins: margins, media: media)
      book.load_url(url, user_style || "", user_script || "")
      write_output(book, output, :png, width: width, height: height)
    end

    private

    def write_output(book, output, format, width: -1, height: -1)
      if output.respond_to?(:write)
        (format == :pdf) ? book.write_to_pdf_stream(output) : book.write_to_png_stream(output, width, height)
      else
        (format == :pdf) ? book.write_to_pdf(output.to_s) : book.write_to_png(output.to_s, width, height)
      end
    end
  end
end
