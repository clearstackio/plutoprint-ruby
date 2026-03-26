require "thor"

module Plutoprint
  class CLI < Thor
    default_command :convert

    desc "convert INPUT OUTPUT", "Convert HTML/XML file or URL to PDF/PNG"
    long_desc <<~DESC
      Convert an HTML or XML file (or URL) to PDF or PNG output.

      INPUT can be a local file path or a URL (http:// or https://).
      OUTPUT format is determined by the file extension (.pdf or .png).
    DESC
    option :size, type: :string, default: "a4", desc: "Page size (a3, a4, a5, b4, b5, letter, legal, ledger)"
    option :margins, type: :string, default: "normal", desc: "Page margins (none, normal, narrow, moderate, wide)"
    option :media, type: :string, default: "print", desc: "Media type (print, screen)"
    option :width, type: :numeric, default: -1, desc: "Image width for PNG output"
    option :height, type: :numeric, default: -1, desc: "Image height for PNG output"
    option :page_width, type: :string, desc: "Custom page width (e.g., 210mm, 8.5in)"
    option :page_height, type: :string, desc: "Custom page height (e.g., 297mm, 11in)"
    option :margin_top, type: :string, desc: "Custom top margin (e.g., 1in, 25mm)"
    option :margin_right, type: :string, desc: "Custom right margin"
    option :margin_bottom, type: :string, desc: "Custom bottom margin"
    option :margin_left, type: :string, desc: "Custom left margin"
    option :title, type: :string, desc: "PDF metadata: title"
    option :author, type: :string, desc: "PDF metadata: author"
    option :subject, type: :string, desc: "PDF metadata: subject"
    option :keywords, type: :string, desc: "PDF metadata: keywords"
    option :creator, type: :string, desc: "PDF metadata: creator"
    option :user_style, type: :string, desc: "User stylesheet (CSS string or file path)"
    option :user_script, type: :string, desc: "User script (JS string or file path)"
    def convert(input, output)
      size = resolve_page_size
      margins = resolve_page_margins
      media = options[:media].to_sym

      book = Book.new(size: size, margins: margins, media: media)

      user_style = load_style_or_script(options[:user_style])
      user_script = load_style_or_script(options[:user_script])

      if url?(input)
        book.load_url(input, user_style, user_script)
      else
        input_path = File.expand_path(input)
        unless File.exist?(input_path)
          warn "Error: file not found: #{input_path}"
          exit 1
        end
        book.load_url("file://#{input_path}", user_style, user_script)
      end

      set_pdf_metadata(book)

      output_path = File.expand_path(output)
      if png_output?(output_path)
        book.write_to_png(output_path, options[:width].to_i, options[:height].to_i)
      else
        book.write_to_pdf(output_path)
      end

      warn "Written: #{output_path} (#{File.size(output_path)} bytes)"
    end

    desc "version", "Print plutoprint version"
    def version
      puts "plutoprint-ruby #{Plutoprint::VERSION} (plutobook #{Plutoprint::PLUTOBOOK_VERSION_STRING})"
    end

    desc "info", "Print build information"
    def info
      puts "plutoprint-ruby #{Plutoprint::VERSION}"
      puts "plutobook #{Plutoprint::PLUTOBOOK_VERSION_STRING}"
      puts Plutoprint.plutobook_build_info
    end

    private

    def resolve_page_size
      if options[:page_width] || options[:page_height]
        w = options[:page_width] ? Plutoprint.parse_length(options[:page_width]) : Plutoprint::PAGE_SIZE_A4.width
        h = options[:page_height] ? Plutoprint.parse_length(options[:page_height]) : Plutoprint::PAGE_SIZE_A4.height
        PageSize.new(w, h)
      else
        options[:size].to_sym
      end
    end

    def resolve_page_margins
      if options[:margin_top] || options[:margin_right] || options[:margin_bottom] || options[:margin_left]
        default = PageMargins.resolve(options[:margins].to_sym)
        t = options[:margin_top] ? Plutoprint.parse_length(options[:margin_top]) : default.top
        r = options[:margin_right] ? Plutoprint.parse_length(options[:margin_right]) : default.right
        b = options[:margin_bottom] ? Plutoprint.parse_length(options[:margin_bottom]) : default.bottom
        l = options[:margin_left] ? Plutoprint.parse_length(options[:margin_left]) : default.left
        PageMargins.new(t, r, b, l)
      else
        options[:margins].to_sym
      end
    end

    def set_pdf_metadata(book)
      book.set_metadata(:creation_date, Time.now.strftime("%Y-%m-%dT%H:%M:%S%:z"))

      {title: :title, author: :author, subject: :subject,
       keywords: :keywords, creator: :creator}.each do |opt_key, meta_key|
        book.set_metadata(meta_key, options[opt_key]) if options[opt_key]
      end
    end

    def url?(input)
      input.match?(%r{\Ahttps?://})
    end

    def png_output?(path)
      File.extname(path).downcase == ".png"
    end

    def load_style_or_script(value)
      return "" if value.nil? || value.empty?
      if File.exist?(value)
        File.read(value)
      else
        value
      end
    end
  end
end
