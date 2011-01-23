module EventMachine
  class HttpRequest
    def self.new(uri, options={})
      begin
        req = HttpOptions.new(uri, options)

        s = EventMachine.connect(req.host, req.port, HttpConnection) do |c|
          c.opts = req

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