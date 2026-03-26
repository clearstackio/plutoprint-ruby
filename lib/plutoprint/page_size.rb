module Plutoprint
  class PageSize
    SIZE_MAP = {
      none: PAGE_SIZE_NONE,
      a3: PAGE_SIZE_A3,
      a4: PAGE_SIZE_A4,
      a5: PAGE_SIZE_A5,
      b4: PAGE_SIZE_B4,
      b5: PAGE_SIZE_B5,
      letter: PAGE_SIZE_LETTER,
      legal: PAGE_SIZE_LEGAL,
      ledger: PAGE_SIZE_LEDGER
    }.freeze

    def to_a
      [width, height]
    end

    def to_h
      {width: width, height: height}
    end

    def inspect
      "Plutoprint::PageSize(#{width}, #{height})"
    end

    def self.resolve(value)
      case value
      when Symbol
        SIZE_MAP.fetch(value) { raise ArgumentError, "unknown page size: #{value.inspect}" }
      when PageSize
        value
      else
        raise TypeError, "expected Symbol or PageSize, got #{value.class}"
      end
    end
  end
end
