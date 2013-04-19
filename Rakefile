require "bundler/gem_tasks"

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = ["spec/backburner_mailer_spec.rb"]
end

task :default => :spec
