module Plutoprint
  class Configuration
    attr_accessor :options, :use_pdf_middleware, :use_png_middleware,
      :ignore_path, :ignore_request, :root_url

    def initialize
      @options = {}
      @use_pdf_middleware = true
      @use_png_middleware = false
      @ignore_path = nil
      @ignore_request = nil
      @root_url = nil
    end
  end
end
