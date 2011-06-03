require 'oauth'
require 'oauth/client/em_http'

module EventMachine
  module Middleware

    class OAuth
      def initialize(opts = {})
        @consumer = ::OAuth::Consumer.new(opts[:consumer_key], opts[:consumer_secret])
        @access_token = ::OAuth::AccessToken.new(@consumer, opts[:access_token], opts[:access_token_secret])
      end

      def request(client, head, body)
        @consumer.sign!(client, @access_token)
        head.merge!(client.req.headers)

        [head,body]
      end
    end
  end
end
