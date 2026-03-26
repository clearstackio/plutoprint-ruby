require "spec_helper"

RSpec.describe Plutoprint::PageSize do
  describe ".new" do
    it "creates a page size with zero args (0, 0)" do
      size = described_class.new
      expect(size.width).to eq(0.0)
      expect(size.height).to eq(0.0)
    end

    it "creates a page size with one arg (w, w)" do
      size = described_class.new(100)
      expect(size.width).to eq(100.0)
      expect(size.height).to eq(100.0)
    end

    it "creates a page size with two args (w, h)" do
      size = described_class.new(200, 300)
      expect(size.width).to eq(200.0)
      expect(size.height).to eq(300.0)
    end
  end

  describe "#landscape" do
    it "returns a new PageSize with width >= height" do
      size = described_class.new(100, 200)
      landscape = size.landscape
      expect(landscape.width).to eq(200.0)
      expect(landscape.height).to eq(100.0)
    end

    it "keeps dimensions when already landscape" do
      size = described_class.new(300, 200)
      landscape = size.landscape
      expect(landscape.width).to eq(300.0)
      expect(landscape.height).to eq(200.0)
    end
  end

  describe "#portrait" do
    it "returns a new PageSize with width <= height" do
      size = described_class.new(300, 200)
      portrait = size.portrait
      expect(portrait.width).to eq(200.0)
      expect(portrait.height).to eq(300.0)
    end

    it "keeps dimensions when already portrait" do
      size = described_class.new(100, 200)
      portrait = size.portrait
      expect(portrait.width).to eq(100.0)
      expect(portrait.height).to eq(200.0)
    end
  end

  describe "#==" do
    it "returns true for equal page sizes" do
      a = described_class.new(100, 200)
      b = described_class.new(100, 200)
      expect(a).to eq(b)
    end

    it "returns false for different page sizes" do
      a = described_class.new(100, 200)
      b = described_class.new(200, 100)
      expect(a).not_to eq(b)
    end

    it "returns false when compared to non-PageSize" do
      a = described_class.new(100, 200)
      expect(a).not_to eq("not a page size")
    end
  end

  describe ".resolve" do
    it "resolves :a4 to PAGE_SIZE_A4" do
      expect(described_class.resolve(:a4)).to eq(Plutoprint::PAGE_SIZE_A4)
    end

    it "resolves :letter to PAGE_SIZE_LETTER" do
      expect(described_class.resolve(:letter)).to eq(Plutoprint::PAGE_SIZE_LETTER)
    end

    it "passes through a PageSize instance" do
      size = described_class.new(100, 200)
      expect(described_class.resolve(size)).to equal(size)
    end

    it "raises ArgumentError for unknown symbol" do
      expect { described_class.resolve(:unknown) }.to raise_error(ArgumentError, /unknown page size/)
    end

    it "raises TypeError for wrong type" do
      expect { described_class.resolve(42) }.to raise_error(TypeError, /expected Symbol or PageSize/)
    end
  end

  describe "#to_a" do
    it "returns [width, height]" do
      size = described_class.new(100, 200)
      expect(size.to_a).to eq([100.0, 200.0])
    end
  end

  describe "#to_h" do
    it "returns {width:, height:}" do
      size = described_class.new(100, 200)
      expect(size.to_h).to eq({width: 100.0, height: 200.0})
    end
  end

  describe "#inspect" do
    it "returns a readable string" do
      size = described_class.new(100, 200)
      expect(size.inspect).to eq("Plutoprint::PageSize(100.0, 200.0)")
    end
  end

  describe "preset constants" do
    it "defines PAGE_SIZE_NONE" do
      size = Plutoprint::PAGE_SIZE_NONE
      expect(size).to be_a(described_class)
      expect(size.width).to eq(0.0)
      expect(size.height).to eq(0.0)
    end

    it "defines PAGE_SIZE_A3" do
      expect(Plutoprint::PAGE_SIZE_A3).to be_a(described_class)
      expect(Plutoprint::PAGE_SIZE_A3.width).to be > 0
      expect(Plutoprint::PAGE_SIZE_A3.height).to be > 0
    end

    it "defines PAGE_SIZE_A4" do
      expect(Plutoprint::PAGE_SIZE_A4).to be_a(described_class)
      expect(Plutoprint::PAGE_SIZE_A4.width).to be > 0
      expect(Plutoprint::PAGE_SIZE_A4.height).to be > 0
    end

    it "defines PAGE_SIZE_A5" do
      expect(Plutoprint::PAGE_SIZE_A5).to be_a(described_class)
    end

    it "defines PAGE_SIZE_B4" do
      expect(Plutoprint::PAGE_SIZE_B4).to be_a(described_class)
    end

    it "defines PAGE_SIZE_B5" do
      expect(Plutoprint::PAGE_SIZE_B5).to be_a(described_class)
    end

    it "defines PAGE_SIZE_LETTER" do
      expect(Plutoprint::PAGE_SIZE_LETTER).to be_a(described_class)
    end

    it "defines PAGE_SIZE_LEGAL" do
      expect(Plutoprint::PAGE_SIZE_LEGAL).to be_a(described_class)
    end

    it "defines PAGE_SIZE_LEDGER" do
      expect(Plutoprint::PAGE_SIZE_LEDGER).to be_a(described_class)
    end
  end
end
