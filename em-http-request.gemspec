# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-http/version"

Gem::Specification.new do |s|
  s.name        = "em-http-request"
  s.version     = EventMachine::HttpRequest::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik"]
  s.email       = ["ilya@igvita.com"]
  s.homepage    = "http://github.com/igrigorik/em-http-request"
  s.summary     = "EventMachine based, async HTTP Request client"
  s.description = s.summary
  s.rubyforge_project = "em-http-request"

  s.add_dependency "eventmachine", ">= 0.12.9"
  s.add_dependency "addressable", ">= 2.0.0"
  s.add_dependency "http_parser.rb"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "em-websocket"
  s.add_development_dependency "rack"
  s.add_development_dependency "mongrel", "~> 1.2.0.pre2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end