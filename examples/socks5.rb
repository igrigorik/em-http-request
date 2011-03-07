require 'rubygems'
require 'eventmachine'
require '../lib/em-http'

EM.run do
  # Establish a SOCKS5 tunnel via SSH
  # ssh -D 8000 some_remote_machine

  connection_options = {:proxy => {:host => '127.0.0.1', :port => 8000, :type => :socks5}}
  http = EM::HttpRequest.new('http://igvita.com/', connection_options).get :redirects => 2

  http.callback {
    puts "#{http.response_header.status} - #{http.response.length} bytes\n"
    puts http.response
    EM.stop
  }

  http.errback {
    puts "Error: " + http.error
    puts http.inspect
    EM.stop
  }
end
