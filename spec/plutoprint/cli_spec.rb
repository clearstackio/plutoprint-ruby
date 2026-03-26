require "spec_helper"
require "plutoprint/cli"
require "tmpdir"

RSpec.describe Plutoprint::CLI do
  describe "convert" do
    it "converts an HTML file to PDF" do
      fixture = File.expand_path("../fixtures/sample.html", __dir__)
      Dir.mktmpdir do |dir|
        output = File.join(dir, "output.pdf")
        cli = Plutoprint::CLI.new
        # Capture stderr since the CLI writes status there
        expect {
          cli.invoke(:convert, [fixture, output])
        }.to output(/Written:/).to_stderr
        expect(File.exist?(output)).to be true
        expect(File.size(output)).to be > 0
        expect(File.binread(output, 5)).to eq("%PDF-")
      end
    end

    it "converts an HTML file to PNG" do
      fixture = File.expand_path("../fixtures/sample.html", __dir__)
      Dir.mktmpdir do |dir|
        output = File.join(dir, "output.png")
        cli = Plutoprint::CLI.new
        expect {
          cli.invoke(:convert, [fixture, output])
        }.to output(/Written:/).to_stderr
        expect(File.exist?(output)).to be true
        expect(File.size(output)).to be > 0
      end
    end
  end

  describe "version" do
    it "prints the version" do
      cli = Plutoprint::CLI.new
      expect {
        cli.invoke(:version)
      }.to output(/plutoprint-ruby #{Plutoprint::VERSION}/o).to_stdout
    end
  end

  describe "info" do
    it "prints build information" do
      cli = Plutoprint::CLI.new
      expect {
        cli.invoke(:info)
      }.to output(/plutobook/).to_stdout
    end
  end
end
