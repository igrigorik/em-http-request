# Courtesy of Darcy Laycock:
# http://gist.github.com/265261
#

require 'rubygems'

require 'em-http'
require 'oauth'

# At a minimum, require 'oauth/request_proxy/em_http_request'
# for this example, we'll use Net::HTTP like support.
require 'oauth/client/em_http'

# You need two things: an oauth consumer and an access token.
# You need to generate an access token, I suggest looking elsewhere how to do that or wait for a full tutorial.
# For a consumer key / consumer secret, signup for an app at:
# http://twitter.com/apps/new

# Edit in your details.
CONSUMER_KEY = ""
CONSUMER_SECRET = ""
ACCESS_TOKEN = ""
ACCESS_TOKEN_SECRET = ""

def twitter_oauth_consumer
  @twitter_oauth_consumer ||= OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "http://twitter.com")
end

def twitter_oauth_access_token
  @twitter_oauth_access_token ||= OAuth::AccessToken.new(twitter_oauth_consumer, ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
end

EM.run do

  request = EventMachine::HttpRequest.new('http://twitter.com/statuses/update.json')
  http = request.post(:body => {'status' => 'Hello Twitter from em-http-request with OAuth'}, :head => {"Content-Type" => "application/x-www-form-urlencoded"}) do |client|
    twitter_oauth_consumer.sign!(client, twitter_oauth_access_token)
  end

  http.callback do
    puts "Response: #{http.response} (Code: #{http.response_header.status})"
    EM.stop_event_loop
  end

  http.errback do
    puts "Failed to post"
    EM.stop_event_loop
  end

end