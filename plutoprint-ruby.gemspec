require_relative "lib/plutoprint/version"

Gem::Specification.new do |spec|
  spec.name = "plutoprint-ruby"
  spec.version = Plutoprint::VERSION
  spec.authors = ["Ajaya Agrawalla"]
  spec.summary = "Ruby bindings for the PlutoBook rendering engine"
  spec.description = "Convert HTML, XML, SVG, and images into high-quality PDFs and PNG images using the PlutoBook rendering engine."
  spec.homepage = "https://github.com/clearstackio/plutoprint-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => "https://github.com/clearstackio/plutoprint-ruby",
    "changelog_uri" => "https://github.com/clearstackio/plutoprint-ruby/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "ext/**/*.{c,h,rb}", "exe/*", "LICENSE", "*.md"]
  spec.bindir = "exe"
  spec.executables = ["plutoprint"]
  spec.extensions = ["ext/plutoprint/extconf.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rack", ">= 2.0"
  spec.add_development_dependency "standard", "~> 1.0"
  spec.add_development_dependency "rack-test", "~> 2.0"
  spec.add_development_dependency "rails", ">= 7.0"
end
