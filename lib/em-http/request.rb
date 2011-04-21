module EventMachine
  class HttpRequest
    @middleware = []

    def self.new(uri, options={})
      begin
        connopt = HttpConnectionOptions.new(uri, options)

        EventMachine.connect(connopt.host, connopt.port, HttpConnection) do |c|
          c.connopts = connopt
          c.uri = uri

          c.pending_connect_timeout = connopt.connect_timeout
          c.comm_inactivity_timeout = connopt.inactivity_timeout
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
        conn = EventMachine::FailedConnection.new(uri, connopt)
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
