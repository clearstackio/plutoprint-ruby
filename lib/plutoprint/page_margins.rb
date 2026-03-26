module Plutoprint
  class PageMargins
    MARGINS_MAP = {
      none: PAGE_MARGINS_NONE,
      normal: PAGE_MARGINS_NORMAL,
      narrow: PAGE_MARGINS_NARROW,
      moderate: PAGE_MARGINS_MODERATE,
      wide: PAGE_MARGINS_WIDE
    }.freeze

    def to_a
      [top, right, bottom, left]
    end

    def to_h
      {top: top, right: right, bottom: bottom, left: left}
    end

    def inspect
      "Plutoprint::PageMargins(#{top}, #{right}, #{bottom}, #{left})"
    end

    def self.resolve(value)
      case value
      when Symbol
        MARGINS_MAP.fetch(value) { raise ArgumentError, "unknown page margins: #{value.inspect}" }
      when PageMargins
        value
      else
        raise TypeError, "expected Symbol or PageMargins, got #{value.class}"
      end
    end
  end
end
