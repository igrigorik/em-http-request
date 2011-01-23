module EventMachine

  class HttpConnection < Connection
    include Deferrable

    attr_accessor :req

    def get    options = {}, &blk;  setup_request(:get,   options, &blk);   end
    def head   options = {}, &blk;  setup_request(:head,  options, &blk);   end
    def delete options = {}, &blk;  setup_request(:delete,options, &blk);   end
    def put    options = {}, &blk;  setup_request(:put,   options, &blk);   end
    def post   options = {}, &blk;  setup_request(:post,  options, &blk);   end

    def setup_request(method, options = {})
      c = HttpClient.new(self, HttpOptions.new(@req.uri, options, method), options)
      callback { c.connection_completed }
      @clients.push c
      c
    end

    def post_init
      @clients = []

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
      succeed
    end

    def unbind
      @clients.map {|c| c.unbind }
    end
  end

  class HttpRequest
    def self.new(uri, options={})
      begin
        req = HttpOptions.new(uri, options)

        s = EventMachine.connect(req.host, req.port, HttpConnection) do |c|
          c.req = req

          c.comm_inactivity_timeout = req.options[:timeout]
          c.pending_connect_timeout = req.options[:timeout]
        end

      rescue EventMachine::ConnectionError => e
        # XXX: handle bad DNS case

        # conn = EventMachine::HttpClient.new("")
        # conn.on_error(e.message, true)
        # conn.uri = @req.uri
        # conn
      end
    end
  end
end
