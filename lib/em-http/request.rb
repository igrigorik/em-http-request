module EventMachine

  class FailedConnection
    include Deferrable
    attr_accessor :error

    def get    options = {}, &blk;  self;  end
    def head   options = {}, &blk;  setup_request(:head,  options, &blk);   end
    def delete options = {}, &blk;  setup_request(:delete,options, &blk);   end
    def put    options = {}, &blk;  setup_request(:put,   options, &blk);   end
    def post   options = {}, &blk;  setup_request(:post,  options, &blk);   end

    def method_missing(method, *args, &blk)
      nil
    end
  end

  class HttpRequest
    @middleware = []

    def self.new(uri, options={})
      begin
        req = HttpOptions.new(uri, options)

        s = EventMachine.connect(req.host, req.port, HttpConnection) do |c|
          c.opts = req

          c.pending_connect_timeout = req.options[:connect_timeout]
          c.comm_inactivity_timeout = req.options[:inactivity_timeout]
        end

      rescue EventMachine::ConnectionError => e
        # TODO: need a blank Connection object such that we can create a 
        # regular HTTPConnection class, instead of this silly trickery 

        conn = EventMachine::FailedConnection.new
        conn.error = e.message
        conn.fail
        conn
      end
    end

    def self.use(klass)
      @middleware << klass
    end

    def self.middleware
      @middleware
    end
  end
end
