module EventMachine

  class HttpRequest < Connection
    include Deferrable

    attr_accessor :uri

    def get    options = {}, &blk;  setup_request(:get,   options, &blk);   end
    def head   options = {}, &blk;  setup_request(:head,  options, &blk);   end
    def delete options = {}, &blk;  setup_request(:delete,options, &blk);   end
    def put    options = {}, &blk;  setup_request(:put,   options, &blk);   end
    def post   options = {}, &blk;  setup_request(:post,  options, &blk);   end

    def setup_request(method, options, &blk)
      @req = HttpOptions.new(method, @uri, options)

      c = HttpClient.new(self, @req, options)
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
      # @clients.map {|c| c.fail }
    end

    # def new(host, &blk)
    # @uri = host.kind_of?(Addressable::URI) ? host : Addressable::URI::parse(host.to_s)
    # @req = HttpOptions.new(:setup, @uri, {})
    # send_request(&blk)
    # end


    def self.connect(uri, options={}, &blk)
      begin
        @uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
        @uri.port ||= 80

        s = EventMachine.connect(@uri.host, @uri.port, self) do |c|
          c.uri = @uri
        end

        # { |c|
        #   c.uri = @req.uri
        #   c.method = @req.method
        #   c.options = @req.options
        #
        #   blk.call(c) unless blk.nil?
        # }
      rescue EventMachine::ConnectionError => e
        conn = EventMachine::HttpClient.new("")
        conn.on_error(e.message, true)
        conn.uri = @req.uri
        conn
      end
    end
  end
end
