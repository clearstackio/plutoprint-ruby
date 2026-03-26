module Plutoprint
  class PDFCanvas
    def self.open(path, size)
      size = PageSize.resolve(size) if size.is_a?(Symbol)
      canvas = new(path, size)
      yield canvas
    ensure
      canvas&.finish
    end

    def self.open_stream(io, size)
      size = PageSize.resolve(size) if size.is_a?(Symbol)
      canvas = create_for_stream(io, size)
      yield canvas
    ensure
      canvas&.finish
    end
  end
end
