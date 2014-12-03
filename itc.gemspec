# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'itc/version'

Gem::Specification.new do |spec|
  spec.name          = "itc"
  spec.version       = Itc::VERSION
  spec.authors       = ["Joe Ennever"]
  spec.email         = ["joe@dwnldmedia.com"]
  spec.summary       = "Ruby API for iTunes Connect"
  spec.description   = ''
  spec.homepage      = "https://github.com/dwnld/itc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency 'activesupport'
  spec.add_dependency 'mechanize'
  spec.add_dependency 'httparty'
end
