require_relative "plutoprint/version"
require_relative "plutoprint/plutoprint"

# Enum mappings (must come after C extension is loaded)
require_relative "plutoprint/media_type"
require_relative "plutoprint/pdf_metadata"
require_relative "plutoprint/image_format"
require_relative "plutoprint/units"

# Ruby extensions for C-defined classes
require_relative "plutoprint/page_size"
require_relative "plutoprint/page_margins"
require_relative "plutoprint/canvas"
require_relative "plutoprint/image_canvas"
require_relative "plutoprint/pdf_canvas"
require_relative "plutoprint/book"
require_relative "plutoprint/resource_data"
require_relative "plutoprint/resource_fetcher"
require_relative "plutoprint/default_resource_fetcher"

# Convenience methods
require_relative "plutoprint/convenience"

# Configuration
require_relative "plutoprint/configuration"
require_relative "plutoprint/options_helper"
require_relative "plutoprint/html_preprocessor"

module Plutoprint
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def set_options(request, **options)
      request.env["plutoprint.options"] = options
    end
  end
end

# Framework integrations (lazy-loaded)
require_relative "plutoprint/rails/railtie" if defined?(::Rails)
