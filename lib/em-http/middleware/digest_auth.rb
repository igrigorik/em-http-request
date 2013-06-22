module EventMachine
  module Middleware
    require 'digest'
    require 'securerandom'

    class DigestAuth
      include EventMachine::HttpEncoding

      attr_accessor :auth_digest, :is_digest_auth

      def initialize(www_authenticate, opts = {})
        @nonce_count = -1
        @opts = opts
        @digest_params = {
            algorithm: 'MD5' # MD5 is the default hashing algorithm
        }
        if (@is_digest_auth = www_authenticate =~ /^Digest/)
          get_params(www_authenticate)
        end
      end

      def request(client, head, body)
        # Allow HTTP basic auth fallback
        if @is_digest_auth
          head['Authorization'] = build_auth_digest(client.req.method, client.req.uri.path, @opts.merge(@digest_params))
        else
          head['Authorization'] = [@opts[:username], @opts[:password]]
        end
        [head, body]
      end

      def response(resp)
        # If the server responds with the Authentication-Info header, set the nonce to the new value
        if @is_digest_auth && (authentication_info = resp.response_header['Authentication-Info'])
          authentication_info =~ /nextnonce="?(.*?)"?(,|\z)/
          @digest_params[:nonce] = $1
        end
      end

      def build_auth_digest(method, uri, params = nil)
        params = @opts.merge(@digest_params) if !params
        nonce_count = next_nonce

        user = unescape params[:username]
        password = unescape params[:password]

        splitted_algorithm = params[:algorithm].split('-')
        sess = "-sess" if splitted_algorithm[1]
        raw_algorithm = splitted_algorithm[0]
        if %w(MD5 SHA1 SHA2 SHA256 SHA384 SHA512 RMD160).include? raw_algorithm
          algorithm = eval("Digest::#{raw_algorithm}")
        else
          raise "Unknown algorithm: #{raw_algorithm}"
        end
        qop = params[:qop]
        cnonce = make_cnonce if qop or sess
        a1 = if sess
          [
            algorithm.hexdigest("#{params[:username]}:#{params[:realm]}:#{params[:password]}"),
            params[:nonce],
            cnonce,
            ].join ':'
        else
          "#{params[:username]}:#{params[:realm]}:#{params[:password]}"
        end
        ha1 = algorithm.hexdigest a1
        ha2 = algorithm.hexdigest "#{method}:#{uri}"

        request_digest = [ha1, params[:nonce]]
        request_digest.push(('%08x' % @nonce_count), cnonce, qop) if qop
        request_digest << ha2
        request_digest = request_digest.join ':'
        header = [
          "Digest username=\"#{params[:username]}\"",
          "realm=\"#{params[:realm]}\"",
          "algorithm=#{raw_algorithm}#{sess}",
          "uri=\"#{uri}\"",
          "nonce=\"#{params[:nonce]}\"",
          "response=\"#{algorithm.hexdigest(request_digest)[0, 32]}\"",
        ]
        if params[:qop]
          header << "qop=#{qop}"
          header << "nc=#{'%08x' % @nonce_count}"
          header << "cnonce=\"#{cnonce}\""
        end
        header << "opaque=\"#{params[:opaque]}\"" if params.key? :opaque
        header.join(', ')
      end

      # Process the WWW_AUTHENTICATE header to get the authentication parameters
      def get_params(www_authenticate)
        www_authenticate.scan(/(\w+)="?(.*?)"?(,|\z)/).each do |match|
          @digest_params[match[0].to_sym] = match[1]
        end
      end

      # Generate a client nonce
      def make_cnonce
        Digest::MD5.hexdigest [
          Time.now.to_i,
          $$,
          SecureRandom.random_number(2**32),
        ].join ':'
      end

      # Keep track of the nounce count
      def next_nonce
        @nonce_count += 1
      end
    end
  end
end
