require "spec_helper"

RSpec.describe Plutoprint::OptionsHelper do
  describe ".resolve_margins" do
    context "with symbol preset" do
      it "resolves :normal to PAGE_MARGINS_NORMAL" do
        result = described_class.resolve_margins(:normal)
        expect(result).to eq(Plutoprint::PAGE_MARGINS_NORMAL)
      end

      it "resolves :narrow" do
        result = described_class.resolve_margins(:narrow)
        expect(result).to eq(Plutoprint::PAGE_MARGINS_NARROW)
      end

      it "resolves :wide" do
        result = described_class.resolve_margins(:wide)
        expect(result).to eq(Plutoprint::PAGE_MARGINS_WIDE)
      end
    end

    context "with PageMargins instance" do
      it "returns the instance unchanged" do
        margins = Plutoprint::PageMargins.new(10, 20, 30, 40)
        expect(described_class.resolve_margins(margins)).to equal(margins)
      end
    end

    context "with hash of unit strings" do
      it "parses inch values to points" do
        result = described_class.resolve_margins(top: "1in", right: "0.5in", bottom: "1in", left: "0.5in")
        expect(result.top).to be_within(0.01).of(72.0)
        expect(result.right).to be_within(0.01).of(36.0)
        expect(result.bottom).to be_within(0.01).of(72.0)
        expect(result.left).to be_within(0.01).of(36.0)
      end

      it "parses mm values" do
        result = described_class.resolve_margins(top: "25mm", right: "25mm", bottom: "25mm", left: "25mm")
        expect(result.top).to be_within(0.1).of(25.0 * Plutoprint::UNITS_MM)
      end
    end

    context "with hash of numeric points" do
      it "uses values directly as floats" do
        result = described_class.resolve_margins(top: 54, right: 54, bottom: 54, left: 54)
        expect(result.top).to eq(54.0)
        expect(result.right).to eq(54.0)
      end
    end

    context "with missing sides" do
      it "defaults missing sides to 0.0" do
        result = described_class.resolve_margins(top: "1in")
        expect(result.top).to be_within(0.01).of(72.0)
        expect(result.right).to eq(0.0)
        expect(result.bottom).to eq(0.0)
        expect(result.left).to eq(0.0)
      end
    end

    context "with nil/unknown value" do
      it "falls back to :normal" do
        result = described_class.resolve_margins(nil)
        expect(result).to eq(Plutoprint::PAGE_MARGINS_NORMAL)
      end
    end
  end

  describe ".resolve_size" do
    it "resolves symbol to PageSize" do
      expect(described_class.resolve_size(:a4)).to eq(Plutoprint::PAGE_SIZE_A4)
    end

    it "passes through PageSize instance" do
      size = Plutoprint::PageSize.new(100, 200)
      expect(described_class.resolve_size(size)).to equal(size)
    end

    it "falls back to :a4 for unknown" do
      expect(described_class.resolve_size(nil)).to eq(Plutoprint::PAGE_SIZE_A4)
    end
  end

  describe ".resolve_media" do
    it "resolves :print" do
      expect(described_class.resolve_media(:print)).to eq(Plutoprint::MEDIA_TYPE_PRINT)
    end

    it "resolves :screen" do
      expect(described_class.resolve_media(:screen)).to eq(Plutoprint::MEDIA_TYPE_SCREEN)
    end

    it "passes through integer" do
      expect(described_class.resolve_media(Plutoprint::MEDIA_TYPE_SCREEN)).to eq(Plutoprint::MEDIA_TYPE_SCREEN)
    end

    it "falls back to :print for unknown" do
      expect(described_class.resolve_media(nil)).to eq(Plutoprint::MEDIA_TYPE_PRINT)
    end
  end

  describe ".deep_merge" do
    it "recursively merges hashes" do
      base = {a: 1, b: {c: 2, d: 3}}
      override = {b: {c: 99}, e: 5}
      result = described_class.deep_merge(base, override)
      expect(result).to eq({a: 1, b: {c: 99, d: 3}, e: 5})
    end

    it "does not mutate the original hashes" do
      base = {a: {b: 1}}
      override = {a: {c: 2}}
      described_class.deep_merge(base, override)
      expect(base).to eq({a: {b: 1}})
    end
  end

  describe ".build_options" do
    it "merges gem defaults, config, and per-request options" do
      Plutoprint.configure do |config|
        config.options = {size: :letter, media: :screen}
      end

      per_request = {media: :print}
      result = described_class.build_options(per_request)

      expect(result[:size]).to eq(:letter)
      expect(result[:media]).to eq(:print)
      expect(result[:margins]).to eq(:normal)
    end

    it "deep merges margins hash" do
      Plutoprint.configure do |config|
        config.options = {margins: {top: "1in", right: "1in", bottom: "1in", left: "1in"}}
      end

      per_request = {margins: {top: "0.5in"}}
      result = described_class.build_options(per_request)

      expect(result[:margins]).to eq({top: "0.5in", right: "1in", bottom: "1in", left: "1in"})
    end

    after { Plutoprint.instance_variable_set(:@configuration, nil) }
  end
end
