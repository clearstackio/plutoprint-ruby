module Plutoprint
  module OptionsHelper
    GEM_DEFAULTS = {
      size: :a4,
      margins: :normal,
      media: :print,
      user_style: nil,
      user_script: nil
    }.freeze

    def self.resolve_margins(value)
      case value
      when Symbol
        PageMargins.resolve(value)
      when PageMargins
        value
      when Hash
        sides = %i[top right bottom left].map do |side|
          v = value[side]
          case v
          when String then Plutoprint.parse_length(v)
          when Numeric then v.to_f
          else 0.0
          end
        end
        PageMargins.new(*sides)
      else
        PageMargins.resolve(:normal)
      end
    end

    def self.resolve_size(value)
      case value
      when Symbol then PageSize.resolve(value)
      when PageSize then value
      else PageSize.resolve(:a4)
      end
    end

    def self.resolve_media(value)
      case value
      when Symbol then MEDIA_TYPE_MAP.fetch(value, MEDIA_TYPE_PRINT)
      when Integer then value
      else MEDIA_TYPE_PRINT
      end
    end

    def self.deep_merge(base, override)
      result = base.dup
      override.each do |key, value|
        result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
          deep_merge(result[key], value)
        else
          value
        end
      end
      result
    end

    def self.build_options(per_request = nil)
      opts = deep_merge(GEM_DEFAULTS, Plutoprint.configuration.options)
      opts = deep_merge(opts, per_request) if per_request
      opts
    end
  end
end
