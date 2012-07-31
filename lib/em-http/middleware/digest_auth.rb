module EventMachine
  module Middleware
    require 'digest'
    require 'securerandom'
    require 'cgi'

    class DigestAuth
      attr_accessor :auth_digest

      def initialize(www_authenticate, opts = {})
        @nonce_count = -1
        @opts = {}
        # Symbolize the opts hash's keys
        opts.each {|k, v| @opts[k.to_sym] = v}
        @digest_params = {
            algorithm: 'MD5' # MD5 is the default hashing algorithm
          }
          get_params(www_authenticate)
      end

      def request(client, head, body)
        head["Authorization"] = build_auth_digest(client.req.method, client.req.uri.path)
        [head, body]
      end

      def response(resp)
        # If the server respons with the Authentication-Info header, set the nonce to the new value
        if (authentication_info = resp.response_header['Authentication-Info'])
          authentication_info =~ /nextnonce=(\w+)/
          @digest_params[:nonce] = $1
        end
      end

      private
      def build_auth_digest(method, uri)
        nonce_count = next_nonce

        user = CGI.unescape @opts[:username]
        password = CGI.unescape @opts[:password]

        splitted_algorithm = @digest_params[:algorithm].split('-')
        sess = splitted_algorithm[1]
        raw_algorithm = splitted_algorithm[0]
        if %w(MD5 SHA1 SHA2 SHA256 SHA384 SHA512 RMD160).include? raw_algorithm
          algorithm = eval("Digest::#{raw_algorithm}")
        else
          raise Error, "unknown algorithm: #{raw_algorithm}"
        end
        qop = @digest_params[:qop]
        cnonce = make_cnonce if qop or sess
        a1 = if sess
          [
            algorithm.hexdigest("#{@opts[:username]}:#{@digest_params[:realm]}:#{@opts[:password]}"),
            @digest_params[:nonce],
            cnonce,
            ].join ':'
        else
          "#{@opts[:username]}:#{@digest_params[:realm]}:#{@opts[:password]}"
        end
        ha1 = algorithm.hexdigest a1
        ha2 = algorithm.hexdigest "#{method}:#{uri}"

        request_digest = [ha1, @digest_params[:nonce]]
        request_digest.push(('%08x' % @nonce_count), cnonce, qop) if qop
        request_digest << ha2
        request_digest = request_digest.join ':'
        header = [
          "Digest username=\"#{@opts[:username]}\"",
          "realm=\"#{@digest_params[:realm]}\"",
          "algorithm=#{raw_algorithm}",
          "uri=\"#{uri}\"",
          "nonce=\"#{@digest_params[:nonce]}\"",
          "response=\"#{algorithm.hexdigest(request_digest)[0, 32]}\"",
        ]
        if @digest_params[:qop]
          header << "qop=#{qop}"
          header << "nc=#{'%08x' % @nonce_count}"
          header << "cnonce=\"#{cnonce}\""
        end
        header << "opaque=\"#{@digest_params[:opaque]}\"" if @digest_params.key? :opaque
        header.join(', ')
      end

      # Process the WWW_AUTHENTICATE header to get the authentication parameters
      def get_params(www_authenticate)
        chunks = www_authenticate.split(' ')
        method = chunks[0]
        if method == 'Digest'
          chunks.shift
          chunks.each do |chunk|
            splitted_chunk = chunk.split('=')
            # [1..-3] is necessary to avoid keeping symbols like \ and = in the value.
            @digest_params[splitted_chunk[0].to_sym] = splitted_chunk[1][1..-3]
          end
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
