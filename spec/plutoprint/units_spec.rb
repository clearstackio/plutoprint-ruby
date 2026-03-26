require "spec_helper"

RSpec.describe "Plutoprint unit constants" do
  it "defines UNITS_PT as 1.0" do
    expect(Plutoprint::UNITS_PT).to eq(1.0)
  end

  it "defines UNITS_PC as 12.0" do
    expect(Plutoprint::UNITS_PC).to eq(12.0)
  end

  it "defines UNITS_IN as 72.0" do
    expect(Plutoprint::UNITS_IN).to eq(72.0)
  end

  it "defines UNITS_CM as approximately 72.0/2.54" do
    expect(Plutoprint::UNITS_CM).to be_within(0.001).of(72.0 / 2.54)
  end

  it "defines UNITS_MM as approximately 72.0/25.4" do
    expect(Plutoprint::UNITS_MM).to be_within(0.001).of(72.0 / 25.4)
  end

  it "defines UNITS_PX as approximately 72.0/96.0" do
    expect(Plutoprint::UNITS_PX).to be_within(0.001).of(72.0 / 96.0)
  end
end

RSpec.describe "Plutoprint.parse_length" do
  it "parses inches" do
    expect(Plutoprint.parse_length("1in")).to eq(72.0)
  end

  it "parses fractional inches" do
    expect(Plutoprint.parse_length("0.5in")).to eq(36.0)
  end

  it "parses millimeters" do
    expect(Plutoprint.parse_length("25.4mm")).to be_within(0.001).of(72.0)
  end

  it "parses centimeters" do
    expect(Plutoprint.parse_length("2.54cm")).to be_within(0.001).of(72.0)
  end

  it "parses points" do
    expect(Plutoprint.parse_length("72pt")).to eq(72.0)
  end

  it "parses pixels" do
    expect(Plutoprint.parse_length("96px")).to be_within(0.001).of(72.0)
  end

  it "is case insensitive" do
    expect(Plutoprint.parse_length("1IN")).to eq(72.0)
  end

  it "raises ArgumentError for invalid input" do
    expect { Plutoprint.parse_length("abc") }.to raise_error(ArgumentError, /invalid length/)
  end

  it "raises ArgumentError for empty string" do
    expect { Plutoprint.parse_length("") }.to raise_error(ArgumentError, /invalid length/)
  end

  it "raises ArgumentError for number without unit" do
    expect { Plutoprint.parse_length("72") }.to raise_error(ArgumentError, /invalid length/)
  end

  it "raises ArgumentError for nil" do
    expect { Plutoprint.parse_length(nil) }.to raise_error(ArgumentError, /invalid length/)
  end
end
