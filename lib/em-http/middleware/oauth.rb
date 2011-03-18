require 'oauth/helper'
require 'oauth/signature/hmac/sha1'
require 'uri'

module EventMachine
  module Middleware

    class OAuth
      SIGNATURE_METHOD = "HMAC-SHA1"
      OAUTH_VERSION = "1.0"

      def initialize(ckey, csecret, atoken, asecret)
        @consumer_key = ckey
        @consumer_secret = csecret
        @access_token = atoken
        @access_token_secret = asecret
      end

      def normalize_string(raw_string)
        unsafe = /[^a-zA-Z0-9\-_\.~]+|[\&]+/i
        URI.escape(raw_string, unsafe)
      end

      def generate_base_string(http_method, url, parameters)
        safe_parameters = normalize_string parameters
        safe_http_method = normalize_string http_method
        url = url.to_s.gsub(':80', '')
        safe_url = url
      end

      def sign(key, base_string)
        digest = OpenSSL::Digest::Digest.new("sha1")
        hmac = OpenSSL::HMAC.digest(digest, key, base_string)
        Base64.encode64(hmac).chomp.gsub(/\n/, '')
      end

      def request(client, head, body)
        oauth_nonce = ::OAuth::Helper.generate_key
        oauth_timestamp = ::OAuth::Helper.generate_timestamp

        raw_oauth_parameters = "OAuth oauth_consumer_key=#{@consumer_key}&" + \
          "oauth_nonce=#{oauth_nonce}&" + \
          "oauth_signature_method=#{SIGNATURE_METHOD}&" + \
          "oauth_timestamp=#{oauth_timestamp}&" + \
          "oauth_token=#{@access_token}&" + \
          "oauth_version=#{OAUTH_VERSION}"

          secret_key = "#{@consumer_secret}&#{@access_token_secret}"
        base_string = generate_base_string(client.req.method, client.req.uri, raw_oauth_parameters)
        oauth_signature = normalize_string(sign(secret_key, base_string)).gsub("=","%3D")

        head["authorization"] = "OAuth oauth_nonce=\"#{oauth_nonce}\", " + \
          "oauth_signature_method=\"#{SIGNATURE_METHOD}\", " + \
          "oauth_timestamp=\"#{oauth_timestamp}\", " + \
          "oauth_consumer_key=\"#{@consumer_key}\", " + \
          "oauth_token=\"#{@access_token}\", " + \
          "oauth_signature=\"#{oauth_signature}\", " + \
          "oauth_version=\"#{OAUTH_VERSION}\""

        # body = raw_oauth_parameters + (body.map {|k,v| "&#{k}=" << normalize_string(v) } rescue '')
        require 'pp'
        pp head
        p body

        [head,body]
      end
    end
  end
end
