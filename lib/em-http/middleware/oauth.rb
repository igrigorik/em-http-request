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

        params = request.query.to_a + body.to_a

        head["Authorization"] = SimpleOAuth::Header.new(request.method, request.uri, params, @opts)

        [head,body]
      end
    end
  end
end
