require 'simple_oauth'

module EventMachine
  module Middleware

    class OAuth
      def initialize(opts = {})
        @opts = opts.dup
        # Allow both `oauth` gem and `simple_oauth` gem opts formats
        @opts[:token] ||= @opts.delete(:access_token)
        @opts[:token_secret] ||= @opts.delete(:access_token_secret)
      end

      def request(client, head, body)
        request = client.req

        head["Authorization"] = SimpleOAuth::Header.new(request.method, request.uri, body, @opts)

        [head,body]
      end
    end
  end
end
