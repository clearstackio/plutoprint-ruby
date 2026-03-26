require "rake/extensiontask"
require "rspec/core/rake_task"
require "standard/rake"

Rake::ExtensionTask.new("plutoprint") do |ext|
  ext.lib_dir = "lib/plutoprint"
end

RSpec::Core::RakeTask.new(:spec)
task default: [:compile, :spec, :standard]
