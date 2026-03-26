require "spec_helper"

RSpec.describe Plutoprint::PageMargins do
  describe ".new" do
    it "creates page margins with zero args (all 0)" do
      margins = described_class.new
      expect(margins.top).to eq(0.0)
      expect(margins.right).to eq(0.0)
      expect(margins.bottom).to eq(0.0)
      expect(margins.left).to eq(0.0)
    end

    it "creates page margins with one arg (all same)" do
      margins = described_class.new(10)
      expect(margins.top).to eq(10.0)
      expect(margins.right).to eq(10.0)
      expect(margins.bottom).to eq(10.0)
      expect(margins.left).to eq(10.0)
    end

    it "creates page margins with two args (top/bottom, right/left)" do
      margins = described_class.new(10, 20)
      expect(margins.top).to eq(10.0)
      expect(margins.right).to eq(20.0)
      expect(margins.bottom).to eq(10.0)
      expect(margins.left).to eq(20.0)
    end

    it "creates page margins with three args (top, right/left, bottom)" do
      margins = described_class.new(10, 20, 30)
      expect(margins.top).to eq(10.0)
      expect(margins.right).to eq(20.0)
      expect(margins.bottom).to eq(30.0)
      expect(margins.left).to eq(20.0)
    end

    it "creates page margins with four args (top, right, bottom, left)" do
      margins = described_class.new(10, 20, 30, 40)
      expect(margins.top).to eq(10.0)
      expect(margins.right).to eq(20.0)
      expect(margins.bottom).to eq(30.0)
      expect(margins.left).to eq(40.0)
    end
  end

  describe ".resolve" do
    it "resolves :normal to PAGE_MARGINS_NORMAL" do
      expect(described_class.resolve(:normal)).to eq(Plutoprint::PAGE_MARGINS_NORMAL)
    end

    it "resolves :narrow to PAGE_MARGINS_NARROW" do
      expect(described_class.resolve(:narrow)).to eq(Plutoprint::PAGE_MARGINS_NARROW)
    end

    it "passes through a PageMargins instance" do
      margins = described_class.new(10, 20, 30, 40)
      expect(described_class.resolve(margins)).to equal(margins)
    end

    it "raises ArgumentError for unknown symbol" do
      expect { described_class.resolve(:unknown) }.to raise_error(ArgumentError, /unknown page margins/)
    end

    it "raises TypeError for wrong type" do
      expect { described_class.resolve(42) }.to raise_error(TypeError, /expected Symbol or PageMargins/)
    end
  end

  describe "#to_a" do
    it "returns [top, right, bottom, left]" do
      margins = described_class.new(10, 20, 30, 40)
      expect(margins.to_a).to eq([10.0, 20.0, 30.0, 40.0])
    end
  end

  describe "#to_h" do
    it "returns {top:, right:, bottom:, left:}" do
      margins = described_class.new(10, 20, 30, 40)
      expect(margins.to_h).to eq({top: 10.0, right: 20.0, bottom: 30.0, left: 40.0})
    end
  end

  describe "#inspect" do
    it "returns a readable string" do
      margins = described_class.new(10, 20, 30, 40)
      expect(margins.inspect).to eq("Plutoprint::PageMargins(10.0, 20.0, 30.0, 40.0)")
    end
  end

  describe "#==" do
    it "returns true for equal page margins" do
      a = described_class.new(10, 20, 30, 40)
      b = described_class.new(10, 20, 30, 40)
      expect(a).to eq(b)
    end

    it "returns false for different page margins" do
      a = described_class.new(10, 20, 30, 40)
      b = described_class.new(40, 30, 20, 10)
      expect(a).not_to eq(b)
    end

    it "returns false when compared to non-PageMargins" do
      a = described_class.new(10)
      expect(a).not_to eq("not margins")
    end
  end

  describe "preset constants" do
    it "defines PAGE_MARGINS_NONE" do
      margins = Plutoprint::PAGE_MARGINS_NONE
      expect(margins).to be_a(described_class)
      expect(margins.top).to eq(0.0)
      expect(margins.right).to eq(0.0)
      expect(margins.bottom).to eq(0.0)
      expect(margins.left).to eq(0.0)
    end

    it "defines PAGE_MARGINS_NORMAL" do
      margins = Plutoprint::PAGE_MARGINS_NORMAL
      expect(margins).to be_a(described_class)
      expect(margins.top).to eq(72.0)
      expect(margins.right).to eq(72.0)
      expect(margins.bottom).to eq(72.0)
      expect(margins.left).to eq(72.0)
    end

    it "defines PAGE_MARGINS_NARROW" do
      margins = Plutoprint::PAGE_MARGINS_NARROW
      expect(margins).to be_a(described_class)
      expect(margins.top).to eq(36.0)
      expect(margins.right).to eq(36.0)
      expect(margins.bottom).to eq(36.0)
      expect(margins.left).to eq(36.0)
    end

    it "defines PAGE_MARGINS_MODERATE" do
      margins = Plutoprint::PAGE_MARGINS_MODERATE
      expect(margins).to be_a(described_class)
      expect(margins.top).to eq(72.0)
      expect(margins.right).to eq(54.0)
      expect(margins.bottom).to eq(72.0)
      expect(margins.left).to eq(54.0)
    end

    it "defines PAGE_MARGINS_WIDE" do
      margins = Plutoprint::PAGE_MARGINS_WIDE
      expect(margins).to be_a(described_class)
      expect(margins.top).to eq(72.0)
      expect(margins.right).to eq(144.0)
      expect(margins.bottom).to eq(72.0)
      expect(margins.left).to eq(144.0)
    end
  end
end
