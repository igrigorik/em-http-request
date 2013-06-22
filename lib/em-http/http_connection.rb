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
      @parent.receive_data data
    end

    def connection_completed
      @parent.connection_completed
    end

    def unbind(reason=nil)
      @parent.unbind(reason)
    end
  end

  class HttpConnection
    include HTTPMethods
    include Socksify
    include Connectify

    attr_reader :deferred
    attr_accessor :error, :connopts, :uri, :conn

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
        c.callback &m.method(:response) if m.respond_to?(:response)
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
        client.parse_response_header(h, @p.http_version, @p.status_code)
        :reset if client.req.no_body?
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
        socksify(client.req.uri.host, client.req.uri.port, *@connopts.proxy[:authorization]) { start }
      elsif @connopts.connect_proxy?
        connectify(client.req.uri.host, client.req.uri.port, *@connopts.proxy[:authorization]) { start }
      else
        start
      end
    end

    def start
      @conn.start_tls(@connopts.tls) if client && client.req.ssl?
      @conn.succeed
    end

    def redirect(client)
      @pending.push client
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

    private

      def client
        @clients.first
      end
  end
end
