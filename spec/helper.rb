require 'rubygems'
require 'bundler/setup'

require 'em-http'
require 'yajl'

require 'stallion'
require 'stub_server'

def failed(http = nil)
  EventMachine.stop
  http ? fail(http.error) : fail
end

def requires_connection(&blk)
  blk.call if system('ping -t1 -c1 google.com &> /dev/null')
end

def requires_port(port, &blk)
  port_open = true
  begin
    s = TCPSocket.new('localhost', port)
    s.close()
  rescue
    port_open = false
  end

  blk.call if port_open
end