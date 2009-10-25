spec = Gem::Specification.new do |s|
  s.name = 'em-http-request'
  s.version = '0.2.0'
  s.date = '2009-10-17'
  s.summary = 'EventMachine based HTTP Request interface'
  s.description = s.summary
  s.email = 'ilya@igvita.com'
  s.homepage = "http://github.com/igrigorik/em-http-request"
  s.has_rdoc = true
  s.authors = ['Ilya Grigorik']
  s.add_dependency('eventmachine', '>= 0.12.9')
  s.add_dependency('addressable', '>= 2.0.0')
  s.extensions = ["ext/buffer/extconf.rb" , "ext/http11_client/extconf.rb"]
  s.rubyforge_project = "em-http-request" 

  # ruby -rpp -e' pp `git ls-files`.split("\n") '
  s.files = [
 ".gitignore",
 "LICENSE",
 "README.rdoc",
 "Rakefile",
 "em-http-request.gemspec",
 "ext/buffer/em_buffer.c",
 "ext/buffer/extconf.rb",
 "ext/http11_client/ext_help.h",
 "ext/http11_client/extconf.rb",
 "ext/http11_client/http11_client.c",
 "ext/http11_client/http11_parser.c",
 "ext/http11_client/http11_parser.h",
 "ext/http11_client/http11_parser.rl",
 "lib/em-http.rb",
 "lib/em-http/client.rb",
 "lib/em-http/core_ext/hash.rb",
 "lib/em-http/decoders.rb",
 "lib/em-http/multi.rb",
 "lib/em-http/request.rb",
 "test/test_hash.rb",
 "test/helper.rb",
 "test/stallion.rb",
 "test/stub_server.rb",
 "test/test_multi.rb",
 "test/test_request.rb"]
end
