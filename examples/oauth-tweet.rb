$: << 'lib' << '../lib'

require 'em-http'
require 'em-http/middleware/oauth'
require 'em-http/middleware/json_response'

require 'pp'

OAuthConfig = {
  :consumer_key     => '',
  :consumer_secret  => '',
  :access_token     => '',
  :access_token_secret => ''
}

EM.run do
  # automatically parse the JSON response into a Ruby object
  EventMachine::AblyHttpRequest::HttpRequest.use EventMachine::AblyHttpRequest::Middleware::JSONResponse

  # sign the request with OAuth credentials
  conn = EventMachine::AblyHttpRequest::HttpRequest.new('http://api.twitter.com/1/statuses/home_timeline.json')
  conn.use EventMachine::AblyHttpRequest::Middleware::OAuth, OAuthConfig

  http = conn.get
  http.callback do
    pp http.response
    EM.stop
  end

  http.errback do
    puts "Failed retrieving user stream."
    pp http.response
    EM.stop
  end
end
