# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'em-http/version'

Gem::Specification.new do |s|
  s.name        = 'em-http-request'
  s.version     = EventMachine::HttpRequest::VERSION

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik"]
  s.email       = ['ilya@igvita.com']
  s.homepage    = 'http://github.com/igrigorik/em-http-request'
  s.summary     = 'EventMachine based, async HTTP Request client'
  s.description = s.summary
  s.license     = 'MIT'
  s.rubyforge_project = 'em-http-request'

  s.add_dependency 'addressable', '>= 2.3.4'
  s.add_dependency 'cookiejar', '!= 0.3.1'
  s.add_dependency 'em-socksify', '>= 0.3'
  s.add_dependency 'eventmachine', '>= 1.0.3'
  s.add_dependency 'http_parser.rb', '>= 0.6.0'

  s.add_development_dependency 'mongrel', '~> 1.2.0.pre2'
  s.add_development_dependency 'multi_json'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
