module EventMachine
  module Socksify

    def self.included(klass)
      klass.class_eval do
        def receive_data(data); proxy_receive_data(data); end
      end
    end

    def proxy_receive_data(data)
      @data ||= ''
      @data << data
      parse_socks_response
    end

    def send_socks_handshake
      # Method Negotiation as described on
      # http://www.faqs.org/rfcs/rfc1928.html Section 3
      @socks_state = :method_negotiation

      methods = socks_methods
      send_data [5, methods.size].pack('CC') + methods.pack('C*')
    end

    def send_socks_connect_request
      begin
        # TO-DO: Implement address types for IPv6 and Domain
        ip_address = Socket.gethostbyname(@opts.uri.host).last
        send_data [5, 1, 0, 1, ip_address, @opts.uri.port].flatten.pack('CCCCA4n')

      rescue
        fail("could not resolve host")
      end
    end

    private

      # parses socks 5 server responses as specified
      # on http://www.faqs.org/rfcs/rfc1928.html
      def parse_socks_response
        if @socks_state == :method_negotiation
          return if not @data.size >= 2

          _, method = @data.slice!(0,2).unpack('CC')

          if socks_methods.include?(method)
            if method == 0
              @socks_state = :connecting
              send_socks_connect_request

            elsif method == 2
              @socks_state = :authenticating
              credentials = @opts.proxy[:authorization]

              username, password = credentials
              send_data [5, username.length, username, password.length, password].pack('CCA*CA*')
            end

          else
            fail("proxy did not accept method")
          end

        elsif @socks_state == :authenticating
          return if not @data.size >= 2

          _, status_code = @data.slice!(0, 2).unpack('CC')

          if status_code == 0 # success
            @socks_state = :connecting
            send_socks_connect_request

          else # error
            fail "access denied by proxy"
          end

        elsif @socks_state == :connecting
          return if not @data.size >= 10

          _, response_code, _, address_type, _, _ = @data.slice(0, 10).unpack('CCCCNn')

          if response_code == 0 # success
            @socks_state = :connected

            # connection_completed will invoke actions to
            # start sending all http data transparently
            # over the socks connection

            # connection_completed
            class << self
              remove_method :receive_data
            end

            start

          else # error
            error_messages = {
              1 => "general socks server failure",
              2 => "connection not allowed by ruleset",
              3 => "network unreachable",
              4 => "host unreachable",
              5 => "connection refused",
              6 => "TTL expired",
              7 => "command not supported",
              8 => "address type not supported"
            }

            error_message = error_messages[response_code] || "unknown error (code: #{response_code})"
            fail "socks5 connect error: #{error_message}"
          end
        end
      end

      def socks_methods
        methods = []
        methods << 2 if !@opts.proxy[:authorization].nil? # 2 => Username/Password Authentication
        methods << 0 # 0 => No Authentication Required

        methods
      end

  end
end