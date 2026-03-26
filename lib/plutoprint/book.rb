module Plutoprint
  class Book
    class << self
      alias_method :_native_new, :new

      def new(*args, size: nil, margins: nil, media: nil)
        if args.any?
          # Positional argument mode: pass through to native new
          _native_new(*args)
        else
          # Keyword argument mode: resolve symbols and use defaults
          size_val = size || PAGE_SIZE_A4
          margins_val = margins || PAGE_MARGINS_NORMAL
          media_val = media || MEDIA_TYPE_PRINT

          size_val = PageSize.resolve(size_val) if size_val.is_a?(Symbol)
          margins_val = PageMargins.resolve(margins_val) if margins_val.is_a?(Symbol)
          media_val = MEDIA_TYPE_MAP.fetch(media_val, media_val) if media_val.is_a?(Symbol)

          _native_new(size_val, margins_val, media_val)
        end
      end
    end

    alias_method :_native_set_metadata, :set_metadata
    def set_metadata(key, value)
      key = PDF_METADATA_MAP.fetch(key, key) if key.is_a?(Symbol)
      _native_set_metadata(key, value)
    end

    alias_method :_native_metadata, :metadata
    def metadata(key)
      key = PDF_METADATA_MAP.fetch(key, key) if key.is_a?(Symbol)
      _native_metadata(key)
    end
  end
end
