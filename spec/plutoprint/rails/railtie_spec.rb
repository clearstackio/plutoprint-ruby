require "spec_helper"

RSpec.describe "Plutoprint::Rails::Railtie" do
  it "railtie file is syntactically valid and references Rails" do
    if defined?(::Rails)
      require "plutoprint/rails/railtie"
      expect(Plutoprint::Rails::Railtie.ancestors).to include(::Rails::Railtie)
    else
      # Without Rails, loading the railtie should raise NameError for Rails constant
      expect {
        load File.expand_path("../../../lib/plutoprint/rails/railtie.rb", __dir__)
      }.to raise_error(NameError, /Rails/)
    end
  end
end
