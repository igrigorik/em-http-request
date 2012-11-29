module EventMachine
  module Middleware
    class OAuth2
      include EM::HttpEncoding
      attr_accessor :access_token

      def initialize(opts={})
        self.access_token = opts[:access_token] or raise "No :access_token provided"
      end

      def request(client, head, body)
        uri = client.req.uri.dup
        update_uri! uri
        client.req.set_uri uri

        [head, body]
      end

      def update_uri!(uri)
        if uri.query.nil?
          uri.query = encode_param(:access_token, access_token)
        else
          uri.query += "&#{encode_param(:access_token, access_token)}"
        end
      end
    end
  end
end
