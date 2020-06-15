require 'em/io_streamer'

module EventMachine

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
    def ssl_verify_peer(cert_string)
      cert = nil
      begin
        cert = OpenSSL::X509::Certificate.new(cert_string)
      rescue OpenSSL::X509::CertificateError
        return false
      end

      @last_seen_cert = cert

      if certificate_store.verify(@last_seen_cert)
        begin
          certificate_store.add_cert(@last_seen_cert)
        rescue OpenSSL::X509::StoreError => e
          raise e unless e.message == 'cert already in hash table'
        end
        true
      else
        raise OpenSSL::SSL::SSLError.new(%(unable to verify the server certificate for "#{host}"))
      end
    end

    def ssl_handshake_completed
      unless verify_peer?
        warn "[WARNING; em-http-request] TLS hostname validation is disabled (use 'tls: {verify_peer: true}'), see" +
             " CVE-2020-13482 and https://github.com/igrigorik/em-http-request/issues/339 for details" unless parent.connopts.tls.has_key?(:verify_peer)
        return true
      end

      unless OpenSSL::SSL.verify_certificate_identity(@last_seen_cert, host)
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

    def certificate_store
      @certificate_store ||= begin
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        ca_file = parent.connopts.tls[:cert_chain_file]
        store.add_file(ca_file) if ca_file
        store
      end
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
      c ||= HttpClient.new(self, HttpClientOptions.new(@uri, options, method))
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
      EventMachine::IOStreamer.new(self, io, opts)
    end

    private

      def client
        @clients.first
      end
  end
end
