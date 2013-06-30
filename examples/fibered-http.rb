$: << 'lib' << '../lib'

require 'eventmachine'
require 'em-http'
require 'fiber'

# Using Fibers in Ruby 1.9 to simulate blocking IO / IO scheduling
# while using the async EventMachine API's

def async_fetch(url)
  f = Fiber.current
  http = EventMachine::HttpRequest.new(url, :connect_timeout => 10, :inactivity_timeout => 20).get

  http.callback { f.resume(http) }
  http.errback  { f.resume(http) }

  Fiber.yield

  if http.error
    p [:HTTP_ERROR, http.error]
  end

  http
end

EventMachine.run do
  Fiber.new{

    puts "Setting up HTTP request #1"
    data = async_fetch('http://0.0.0.0/')
    puts "Fetched page #1: #{data.response_header.status}"

    puts "Setting up HTTP request #2"
    data = async_fetch('http://www.yahoo.com/')
    puts "Fetched page #2: #{data.response_header.status}"

    puts "Setting up HTTP request #3"
    data = async_fetch('http://non-existing.domain/')
    puts "Fetched page #3: #{data.response_header.status}"

    EventMachine.stop
  }.resume
end

puts "Done"

#  Setting up HTTP request #1
#  Fetched page #1: 302
#  Setting up HTTP request #2
#  Fetched page #2: 200
#  Done
