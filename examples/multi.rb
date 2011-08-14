$: << '../lib' << 'lib'

require 'eventmachine'
require 'em-http'

EventMachine.run {
  multi = EventMachine::MultiRequest.new

  reqs = [
    'http://google.com/',
    'http://google.ca:81/'
  ]

  reqs.each_with_index do |url, idx|
    http = EventMachine::HttpRequest.new(url, :connect_timeout => 1)
    req = http.get
    multi.add idx, req
  end

  multi.callback  do
    p multi.responses[:callback].size
    p multi.responses[:errback].size
    EventMachine.stop
  end
}
