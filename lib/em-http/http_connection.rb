module EventMachine
  class HttpConnection < Connection
    include Deferrable

    attr_accessor :opts

    def get    options = {}, &blk;  setup_request(:get,   options, &blk);   end
    def head   options = {}, &blk;  setup_request(:head,  options, &blk);   end
    def delete options = {}, &blk;  setup_request(:delete,options, &blk);   end
    def put    options = {}, &blk;  setup_request(:put,   options, &blk);   end
    def post   options = {}, &blk;  setup_request(:post,  options, &blk);   end

    def setup_request(method, options = {})
      c = HttpClient.new(self, HttpOptions.new(@opts.uri, options, method), options)
      callback { c.connection_completed }
      @clients.push c
      c
    end

    def post_init
      @clients = []
      @pending = []

      @p = Http::Parser.new
      @p.on_headers_complete = proc do |h|
        @clients.first.parse_response_header(h, @p.http_version, @p.status_code)
      end

      @p.on_body = proc do |b|
        @clients.first.on_body_data(b)
      end

      @p.on_message_complete = proc do
        c = @clients.shift
        c.state = :finished
        c.on_request_complete
      end
    end

    def receive_data(data)
      @p << data
    end

    def connection_completed
      ssl = @opts.options[:tls] || @opts.options[:ssl] || {}
      start_tls(ssl) if @opts.uri.scheme == "https" or @opts.uri.port == 443

      succeed
    end

    def redirect(client, location)
      client.req.set_uri(location)
      @pending.push client
    rescue Exception => e
      client.on_error(e.message)
    end

    def unbind
      @clients.map {|c| c.unbind }

      if r = @pending.shift
        @clients.push r

        r.reset!
        @p.reset!

        set_deferred_status :unknown
        reconnect(r.req.host, r.req.port)
        callback { r.connection_completed }
      end

    end
  end
end
