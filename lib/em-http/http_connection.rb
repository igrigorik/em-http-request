require 'em/io_streamer'

module EventMachine
  module AblyHttpRequest

    module HTTPMethods
      def get      options = {}, &blk;  setup_request(:get,     options, &blk); end
      def head     options = {}, &blk;  setup_request(:head,    options, &blk); end
      def delete   options = {}, &blk;  setup_request(:delete,  options, &blk); end
      def put      options = {}, &blk;  setup_request(:put,     options, &blk); end
      def post     options = {}, &blk;  setup_request(:post,    options, &blk); end
      def patch    options = {}, &blk;  setup_request(:patch,   options, &blk); end
      def options  options = {}, &blk;  setup_request(:options, options, &blk); end
    end

    class HttpStubConnection < Connection
      include Deferrable
      attr_reader :parent

      def parent=(p)
        @parent = p
        @parent.conn = self
      end

      def receive_data(data)
        begin
          @parent.receive_data data
        rescue EventMachine::Connectify::CONNECTError => e
          @parent.close(e.message)
        end
      end

      def connection_completed
        @parent.connection_completed
      end

      def unbind(reason=nil)
        @parent.unbind(reason)
      end

      # TLS verification support, original implementation by Mislav Marohnić
      # https://github.com/lostisland/faraday/blob/63cf47c95b573539f047c729bd9ad67560bc83ff/lib/faraday/adapter/em_http_ssl_patch.rb
      #
      # Updated by Ably, here’s why:
      #
      # We noticed that the existing verification mechanism is failing in the
      # case where the certificate chain presented by the server contains a
      # certificate that’s signed by an expired trust anchor. At the time of
      # writing, this is the case with some Let’s Encrypt certificate chains,
      # which contain a cross-sign by the expired DST Root X3 CA.
      #
      # This isn’t meant to be an issue; the certificate chain presented by the
      # server still contains a certificate that’s a trust anchor in most
      # modern systems. So in the case where this trust anchor exists, OpenSSL
      # would instead construct a certification path that goes straight to that
      # anchor, bypassing the expired certificate.
      #
      # Unfortunately, as described in
      # https://github.com/eventmachine/eventmachine/issues/954#issue-1014842247,
      # EventMachine misuses OpenSSL in a variety of ways. One of them is that
      # it does not configure a list of trust anchors, meaning that OpenSSL is
      # unable to construct the correct certification path in the manner
      # described above.
      #
      # This means that we end up in a degenerate situation where
      # ssl_verify_peer just receives the certificates in the chain provided by
      # the peer. In the scenario described above, one of these certificates is
      # expired and hence the existing verification mechanism, which "verifies"
      # each certificate provided to ssl_verify_peer, fails.
      #
      # So, instead we remove the existing ad-hoc mechanism for verification
      # (which did things I’m not sure it should have done, like putting
      # non-trust-anchors into an OpenSSL::X509::Store) and instead employ
      # OpenSSL (configured to use the system trust store, and hence able to
      # construct the correct certification path) to do all the hard work of
      # constructing the certification path and then verifying the peer
      # certificate. (This is what, in my opinion, EventMachine ideally would
      # be allowing OpenSSL to do in the first place. Instead, as far as I can
      # tell, it pushes all of this responsibility onto its users, and then
      # provides them with an insufficient API for meeting this
      # responsibility.)
      def ssl_verify_peer(cert_string)
        # We use ssl_verify_peer simply as a mechanism for gathering the
        # certificate chain presented by the peer. In ssl_handshake_completed,
        # we’ll make use of this information in order to verify the peer.
        @peer_certificate_chain ||= []
        begin
          cert = OpenSSL::X509::Certificate.new(cert_string)
          @peer_certificate_chain << cert
          true
        rescue OpenSSL::X509::CertificateError
          return false
        end
      end

      def ssl_handshake_completed
        # It’s not great to have to perform the server certificate verification
        # after the handshake has completed, because it means:
        #
        # - We have to be sure that we don’t send any data over the TLS
        #   connection until we’ve verified the certificate. Created
        #   https://github.com/ably/ably-ruby/issues/400 to understand whether
        #   there’s anything we need to change to be sure of this.
        #
        # - If verification does fail, we have no way of failing the handshake
        #   with a bad_certificate error.
        #
        # Unfortunately there doesn’t seem to be a better alternative within
        # the TLS-related APIs provided to us by EventMachine. (Admittedly I am
        # not familiar with EventMachine.)
        #
        # (Performing the verification post-handshake is not new to the Ably
        # implementation of certificate verification; the previous
        # implementation performed hostname verification after the handshake
        # was complete.)

        # I was quite worried by the description in the aforementioned issue
        # eventmachine/eventmachine#954 of how EventMachine "ignores all errors
        # from the chain construction" and hence I don’t know if there is some
        # weird scenario where, somehow, the calls to ssl_verify_peer terminate
        # with some intermediate certificate instead of with the certificate of
        # the server we’re communicating with. (It's quite possible that this
        # can’t occur and I’m just being paranoid, but I think a bit of
        # paranoia when it comes to security isn't a bad thing.)
        #
        # That's why, instead of the previous code which passed
        # certificate_store.verify the final certificate received by
        # ssl_verify_peer, I explicitly use the result of get_peer_cert, to be
        # sure that the certificate that we’re verifying is the one that the
        # server has demonstrated that they hold the private key for.
        server_certificate = OpenSSL::X509::Certificate.new(get_peer_cert)

        # A sense check to confirm my understanding of what’s in @peer_certificate_chain.
        #
        # (As mentioned above, unless something has gone very wrong, these two
        # certificates should be identical.)
        unless server_certificate == @peer_certificate_chain.last
          raise OpenSSL::SSL::SSLError.new(%(Peer certificate sense check failed for "#{host}"));
        end

        # Verify the server’s certificate against the default trust anchors,
        # aided by the intermediate certificates provided by the server.
        unless create_certificate_store.verify(server_certificate, @peer_certificate_chain[0...-1])
          raise OpenSSL::SSL::SSLError.new(%(unable to verify the server certificate for "#{host}"))
        end

        unless verify_peer?
          warn "[WARNING; ably-em-http-request] TLS hostname validation is disabled (use 'tls: {verify_peer: true}'), see" +
               " CVE-2020-13482 and https://github.com/igrigorik/em-http-request/issues/339 for details" unless parent.connopts.tls.has_key?(:verify_peer)
          return true
        end

        # Verify that the peer’s certificate matches the hostname.
        unless OpenSSL::SSL.verify_certificate_identity(server_certificate, host)
          raise OpenSSL::SSL::SSLError.new(%(host "#{host}" does not match the server certificate))
        else
          true
        end
      end

      def verify_peer?
        parent.connopts.tls[:verify_peer]
      end

      def host
        parent.connopts.host
      end

      def create_certificate_store
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        ca_file = parent.connopts.tls[:cert_chain_file]
        store.add_file(ca_file) if ca_file
        store
      end
    end

    class HttpConnection
      include HTTPMethods
      include Socksify
      include Connectify

      attr_reader :deferred, :conn
      attr_accessor :error, :connopts, :uri

      def initialize
        @deferred = true
        @middleware = []
      end

      def conn=(c)
        @conn = c
        @deferred = false
      end

      def activate_connection(client)
        begin
          EventMachine.bind_connect(@connopts.bind, @connopts.bind_port,
                                    @connopts.host, @connopts.port,
                                    HttpStubConnection) do |conn|
            post_init

            @deferred = false
            @conn = conn

            conn.parent = self
            conn.pending_connect_timeout = @connopts.connect_timeout
            conn.comm_inactivity_timeout = @connopts.inactivity_timeout
          end

          finalize_request(client)
        rescue EventMachine::ConnectionError => e
          #
          # Currently, this can only fire on initial connection setup
          # since #connect is a synchronous method. Hence, rescue the exception,
          # and return a failed deferred which fail any client request at next
          # tick.  We fail at next tick to keep a consistent API when the newly
          # created HttpClient is failed. This approach has the advantage to
          # remove a state check of @deferred_status after creating a new
          # HttpRequest. The drawback is that users may setup a callback which we
          # know won't be used.
          #
          # Once there is async-DNS, then we'll iterate over the outstanding
          # client requests and fail them in order.
          #
          # Net outcome: failed connection will invoke the same ConnectionError
          # message on the connection deferred, and on the client deferred.
          #
          EM.next_tick{client.close(e.message)}
        end
      end

      def setup_request(method, options = {}, c = nil)
        c ||= HttpClient.new(self, ::AblyHttpRequest::HttpClientOptions.new(@uri, options, method))
        @deferred ? activate_connection(c) : finalize_request(c)
        c
      end

      def finalize_request(c)
        @conn.callback { c.connection_completed }

        middleware.each do |m|
          c.callback(&m.method(:response)) if m.respond_to?(:response)
        end

        @clients.push c
      end

      def middleware
        [HttpRequest.middleware, @middleware].flatten
      end

      def post_init
        @clients = []
        @pending = []

        @p = Http::Parser.new
        @p.header_value_type = :mixed
        @p.on_headers_complete = proc do |h|
          if client
            if @p.status_code == 100
              client.send_request_body
              @p.reset!
            else
              client.parse_response_header(h, @p.http_version, @p.status_code)
              :reset if client.req.no_body?
            end
          else
            # if we receive unexpected data without a pending client request
            # reset the parser to avoid firing any further callbacks and close
            # the connection because we're processing invalid HTTP
            @p.reset!
            unbind
            :stop
          end
        end

        @p.on_body = proc do |b|
          client.on_body_data(b)
        end

        @p.on_message_complete = proc do
          if !client.continue?
            c = @clients.shift
            c.state = :finished
            c.on_request_complete
          end
        end
      end

      def use(klass, *args, &block)
        @middleware << klass.new(*args, &block)
      end

      def peer
        Socket.unpack_sockaddr_in(@peer)[1] rescue nil
      end

      def receive_data(data)
        begin
          @p << data
        rescue HTTP::Parser::Error => e
          c = @clients.shift
          c.nil? ? unbind(e.message) : c.on_error(e.message)
        end
      end

      def connection_completed
        @peer = @conn.get_peername

        if @connopts.socks_proxy?
          socksify(client.req.uri.hostname, client.req.uri.inferred_port, *@connopts.proxy[:authorization]) { start }
        elsif @connopts.connect_proxy?
          connectify(client.req.uri.hostname, client.req.uri.inferred_port, *@connopts.proxy[:authorization]) { start }
        else
          start
        end
      end

      def start
        @conn.start_tls(@connopts.tls) if client && client.req.ssl?
        @conn.succeed
      end

      def redirect(client, new_location)
        old_location = client.req.uri
        new_location = client.req.set_uri(new_location)

        if client.req.keepalive
          # Application requested a keep-alive connection but one of the requests
          # hits a cross-origin redirect. We need to open a new connection and
          # let both connections proceed simultaneously.
          if old_location.origin != new_location.origin
            conn = HttpConnection.new
            client.conn = conn
            conn.connopts = @connopts
            conn.connopts.https = new_location.scheme == "https"
            conn.uri = client.req.uri
            conn.activate_connection(client)

          # If the redirect is a same-origin redirect on a keep-alive request
          # then immidiately dispatch the request over existing connection.
          else
            @clients.push client
            client.connection_completed
          end
        else
          # If connection is not keep-alive the unbind will fire and we'll
          # reconnect using the same connection object.
          @pending.push client
        end
      end

      def unbind(reason = nil)
        @clients.map { |c| c.unbind(reason) }

        if r = @pending.shift
          @clients.push r

          r.reset!
          @p.reset!

          begin
            @conn.set_deferred_status :unknown

            if @connopts.proxy
              @conn.reconnect(@connopts.host, @connopts.port)
            else
              @conn.reconnect(r.req.host, r.req.port)
            end

            @conn.pending_connect_timeout = @connopts.connect_timeout
            @conn.comm_inactivity_timeout = @connopts.inactivity_timeout
            @conn.callback { r.connection_completed }
          rescue EventMachine::ConnectionError => e
            @clients.pop.close(e.message)
          end
        else
          @deferred = true
          @conn.close_connection
        end
      end
      alias :close :unbind

      def send_data(data)
        @conn.send_data data
      end

      def stream_file_data(filename, args = {})
        @conn.stream_file_data filename, args
      end

      def stream_data(io, opts = {})
        EventMachine::AblyHttpRequest::IOStreamer.new(self, io, opts)
      end

      private

        def client
          @clients.first
        end
    end
  end
end
