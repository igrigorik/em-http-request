require 'rubygems'
require 'bundler/setup'

require 'em-http'

require 'stallion'
require 'stub_server'

def failed(http = nil)
  EventMachine.stop
  http ? fail(http.error) : fail
end

def requires_connection(&blk)
  blk.call if system('ping google.com &>2 /dev/null')
end
