require "rack"
require "plutoprint"

module Plutoprint
  module Rack
    class Middleware
      PDF_REGEX = /\.pdf$/i
      PNG_REGEX = /\.png$/i

      def initialize(app)
        @app = app
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        @request = ::Rack::Request.new(env)
        @pdf_request = Plutoprint.configuration.use_pdf_middleware && @request.path.match?(PDF_REGEX)
        @png_request = Plutoprint.configuration.use_png_middleware && @request.path.match?(PNG_REGEX)

        if convert_request? && !ignore?
          configure_env(env)
        end

        status, headers, response = @app.call(env)

        if convert_request? && !ignore? && html_content?(headers) && status == 200
          response = convert_response(response, headers, env)
        end

        [status, headers, response]
      ensure
        restore_env(env) if convert_request?
      end

      private

      def convert_request?
        @pdf_request || @png_request
      end

      def ignore?
        ignore_path? || ignore_request?
      end

      def ignore_path?
        ignore_path = Plutoprint.configuration.ignore_path
        case ignore_path
        when String then @request.path.start_with?(ignore_path)
        when Regexp then @request.path.match?(ignore_path)
        when Proc then ignore_path.call(@request.path)
        else false
        end
      end

      def ignore_request?
        ignore_request = Plutoprint.configuration.ignore_request
        return false unless ignore_request.is_a?(Proc)

        ignore_request.call(@request)
      end

      def html_content?(headers)
        content_type = headers["Content-Type"] || headers["content-type"] || ""
        content_type.match?(%r{text/html|application/xhtml\+xml})
      end

      def configure_env(env)
        @pre_request_env = env.slice("PATH_INFO", "REQUEST_URI", "HTTP_ACCEPT")
        env["PATH_INFO"] = @request.path.sub(request_regex, "")
        env["HTTP_ACCEPT"] = [::Rack::Mime.mime_type(".html"), env["HTTP_ACCEPT"]].compact.join(",")
        env["plutoprint.middleware"] = true
      end

      def restore_env(env)
        return unless @pre_request_env.is_a?(Hash)

        env.merge!(@pre_request_env)
      end

      def request_regex
        @pdf_request ? PDF_REGEX : PNG_REGEX
      end

      def convert_response(response, headers, env)
        html = collect_body(response)
        root_url = Plutoprint.configuration.root_url || "#{env["rack.url_scheme"]}://#{env["HTTP_HOST"]}/"
        protocol = env["rack.url_scheme"]
        html = HTMLPreprocessor.process(html, root_url, protocol)

        per_request = env["plutoprint.options"]
        opts = OptionsHelper.build_options(per_request)

        size = OptionsHelper.resolve_size(opts[:size])
        margins = OptionsHelper.resolve_margins(opts[:margins])
        media = OptionsHelper.resolve_media(opts[:media])

        book = Book.new(size, margins, media)
        base_url = root_url
        book.load_html(html, opts[:user_style] || "", opts[:user_script] || "", base_url)

        io = StringIO.new
        if @pdf_request
          book.write_to_pdf_stream(io)
          content_type = "application/pdf"
        else
          book.write_to_png_stream(io)
          content_type = "image/png"
        end

        body = io.string
        # Clear both Rack 2 and Rack 3 header keys to avoid duplicates
        headers.delete("Content-Type")
        headers.delete("content-type")
        headers.delete("Content-Length")
        headers.delete("content-length")
        headers.delete("ETag")
        headers.delete("etag")
        headers.delete("Cache-Control")
        headers.delete("cache-control")

        headers[content_type_key] = content_type
        headers[content_length_key] = body.bytesize.to_s

        [body]
      end

      def collect_body(response)
        body = +""
        response.each { |chunk| body << chunk }
        response.close if response.respond_to?(:close)
        body
      end

      # Rack 3 uses lowercase headers, Rack 2 uses capitalized
      def rack3?
        return @rack3 if defined?(@rack3)

        @rack3 = ::Gem::Version.new(::Rack.release) >= ::Gem::Version.new("3")
      end

      def content_type_key = rack3? ? "content-type" : "Content-Type"
      def content_length_key = rack3? ? "content-length" : "Content-Length"
    end
  end
end
