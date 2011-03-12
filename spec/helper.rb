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