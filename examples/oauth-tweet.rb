require 'rubygems'
require 'eventmachine'
require 'em-http-request'
require 'oauth/helper'
require 'oauth/signature/hmac/sha1'
require 'uri'

module TwitterDemo
	STREAM_URL = "http://twitter.com/statuses/update.json"
	HTTP_METHOD = "POST"

	CONSUMER_KEY = ""
	CONSUMER_SECRET = ""
	ACCESS_TOKEN = ""
	ACCESS_TOKEN_SECRET = ""
	SIGNATURE_METHOD = "HMAC-SHA1"
	OAUTH_VERSION = "1.0"
	TWEET = "Hello Twitter from em-http-request with OAuth"

	class OAuthMiddleware
		
		def self.normalize_string(raw_string)
			unsafe = /[^a-zA-Z0-9\-_\.~]+|[\&]+/i
			URI.escape(raw_string, unsafe)
		end

		def self.generate_base_string(http_method, url, parameters)
			safe_parameters = normalize_string parameters
			safe_http_method = normalize_string http_method
			safe_url = normalize_string url
		end

		def self.sign(key, base_string)
			digest = OpenSSL::Digest::Digest.new("sha1")
			hmac = OpenSSL::HMAC.digest(digest, key, base_string)
			Base64.encode64(hmac).chomp.gsub(/\n/, '')
		end

		def self.request(head, body)
			oauth_nonce = OAuth::Helper.generate_key
			oauth_signature_method = "HMAC-SHA1"
			oauth_timestamp = OAuth::Helper.generate_timestamp

			raw_oauth_parameters = "oauth_consumer_key=#{CONSUMER_KEY}&" + \
														 "oauth_nonce=#{oauth_nonce}&" + \
														 "oauth_signature_method=#{oauth_signature_method}&" + \
														 "oauth_timestamp=#{oauth_timestamp}&" + \
														 "oauth_token=#{ACCESS_TOKEN}&" + \
														 "oauth_version=#{OAUTH_VERSION}"

			body.each do |k, v|
				raw_oauth_parameters << %{&#{k}=} << self.normalize_string(%{#{v}})
			end

			secret_key = "#{CONSUMER_SECRET}&#{ACCESS_TOKEN_SECRET}"
			oauth_signature = self.normalize_string( self.sign(secret_key, self.generate_base_string(HTTP_METHOD, STREAM_URL, raw_oauth_parameters)) ).gsub("=","%3D")

			head["authorization"] = %{OAuth oauth_consumer_key="#{CONSUMER_KEY}", oauth_token="#{ACCESS_TOKEN}",oauth_signature_method="#{oauth_signature_method}", oauth_timestamp="#{oauth_timestamp}", oauth_nonce="#{oauth_nonce}", oauth_signature="#{oauth_signature}", oauth_version="#{OAUTH_VERSION}"}

			[head,body]
		end
	end

	EM.run do
		@request = EventMachine::HttpRequest.new(STREAM_URL)
		@request.use OAuthMiddleware
		http = @request.post :body =>{"status" => TWEET}, :head => {"Accept" => "*/*", "User-Agent" => "propertweet/0.1", "Keep-alive" => "true" }
		
		http.callback do
			puts http.response
			EM.stop_event_loop
		end

		http.errback do
			puts "Failed retrieving user stream."
			puts http.response
			EM.stop_event_loop
		end
	end
end

