require 'simple_oauth'

module EventMachine
  module Middleware

    class OAuth
      include HttpEncoding

      def initialize(opts = {})
        @opts = opts.dup
        # Allow both `oauth` gem and `simple_oauth` gem opts formats
        @opts[:token] ||= @opts.delete(:access_token)
        @opts[:token_secret] ||= @opts.delete(:access_token_secret)
      end

      def request(client, head, body)
        request = client.req

        uri = request.uri.join(encode_query(request.uri, request.query))

        params = {}
        if ["POST", "PUT"].include?(request.method)
          CGI.parse(client.normalize_body(body)).each do |k,v|
            # Since `CGI.parse` always returns values as an array
            params[k] = v.size == 1 ? v.first : v
          end
        end

        head["Authorization"] = SimpleOAuth::Header.new(request.method, uri, params, @opts)

        [head,body]
      end
    end
  end
end
