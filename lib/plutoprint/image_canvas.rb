module Plutoprint
  class ImageCanvas
    def self.open(width, height, format: IMAGE_FORMAT_ARGB32)
      format_val = format.is_a?(Symbol) ? IMAGE_FORMAT_MAP.fetch(format) : format
      canvas = new(width, height, format_val)
      yield canvas
    ensure
      canvas&.finish
    end
  end
end
