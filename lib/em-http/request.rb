module EventMachine
  class HttpRequest
    @middleware = []

    def self.new(uri, options={})
      begin
        req = HttpOptions.new(uri, options)

        EventMachine.connect(req.host, req.port, HttpConnection) do |c|
          c.opts = req

          c.pending_connect_timeout = req.options[:connect_timeout]
          c.comm_inactivity_timeout = req.options[:inactivity_timeout]
        end

      rescue EventMachine::ConnectionError => e
        #
        # Currently, this can only fire on initial connection setup
        # since #connect is a synchronous method. Hence, rescue the
        # exception, and return a failed deferred which will immediately
        # fail any client request.
        #
        # Once there is async-DNS, then we'll iterate over the outstanding
        # client requests and fail them in order.
        #
        # Net outcome: failed connection will invoke the same ConnectionError
        # message on the connection deferred, and on the client deferred.
        #
        conn = EventMachine::FailedConnection.new(req)
        conn.error = e.message
        conn.fail
        conn
      end
    end

    def self.use(klass, *args, &block)
      @middleware << klass.new(*args, &block)
    end

    def self.middleware
      @middleware
    end
  end
end
