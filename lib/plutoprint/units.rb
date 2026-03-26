module Plutoprint
  UNITS_MAP = {
    "pt" => UNITS_PT, "pc" => UNITS_PC, "in" => UNITS_IN,
    "cm" => UNITS_CM, "mm" => UNITS_MM, "px" => UNITS_PX
  }.freeze

  def self.parse_length(value)
    match = value.to_s.downcase.match(/\A(\d+(?:\.\d+)?)(pt|pc|in|cm|mm|px)\z/)
    raise ArgumentError, "invalid length value: '#{value}'" unless match
    match[1].to_f * UNITS_MAP[match[2]]
  end
end
