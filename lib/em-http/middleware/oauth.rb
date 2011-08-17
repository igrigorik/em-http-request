require 'simple_oauth'

module EventMachine
  module Middleware

    class OAuth
      def initialize(opts = {})
        @opts = opts
      end

      def request(client, head, body)
        request = client.req

        head["Authorization"] = SimpleOAuth::Header.new(request.method, request.uri, body, @opts)

        [head,body]
      end
    end
  end
end
