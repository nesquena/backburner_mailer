# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'backburner_mailer/version'

Gem::Specification.new do |spec|
  spec.name          = "backburner_mailer"
  spec.version       = BackburnerMailer::VERSION
  spec.authors       = ["Nathan Esquenazi"]
  spec.email         = ["nesquena@gmail.com"]
  spec.description   = %q{Plugin for sending asynchronous email with Backburner}
  spec.summary       = %q{Plugin for sending asynchronous email with Backburner.}
  spec.homepage      = "https://github.com/nesquena/backburner_mailer"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "backburner"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "actionmailer", "~> 3"
  spec.add_development_dependency("rspec", "~> 2.6")
  spec.add_development_dependency("yard", ">= 0.6.0")
end
