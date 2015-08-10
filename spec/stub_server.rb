class StubServer
  module Server
    attr_accessor :keepalive

    def receive_data(data)
      if echo?
        send_data("HTTP/1.0 200 OK\r\nContent-Length: #{data.bytesize}\r\nContent-Type: text/plain\r\n\r\n")
        send_data(data)
      else
        send_data @response
      end

      close_connection_after_writing unless keepalive
    end

    def echo= flag
      @echo = flag
    end

    def echo?
      !!@echo
    end

    def response=(response)
      @response = response
    end
  end

  def initialize options = {}
    options = {:response => options} if options.kind_of?(String)
    options = {:port     => 8081, :host => '127.0.0.1'}.merge(options)

    host = options[:host]
    port = options[:port]
    @sig = EventMachine::start_server(host, port, Server) do |server|
      server.response  = options[:response]
      server.echo      = options[:echo]
      server.keepalive = options[:keepalive]
    end
  end

  def stop
    EventMachine.stop_server @sig
  end
end
