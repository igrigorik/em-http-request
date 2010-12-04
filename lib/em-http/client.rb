# #--
# Copyright (C)2008 Ilya Grigorik
#
# Includes portion originally Copyright (C)2007 Tony Arcieri
# Includes portion originally Copyright (C)2005 Zed Shaw
# You can redistribute this under the terms of the Ruby
# license See file LICENSE for details
# #--

module EventMachine

  # A simple hash is returned for each request made by HttpClient with the
  # headers that were given by the server for that request.
  class HttpResponseHeader < Hash
    # The reason returned in the http response ("OK","File not found",etc.)
    attr_accessor :http_reason

    # The HTTP version returned.
    attr_accessor :http_version

    # The status code (as a string!)
    attr_accessor :http_status

    # E-Tag
    def etag
      self[HttpClient::ETAG]
    end

    def last_modified
      self[HttpClient::LAST_MODIFIED]
    end

    # HTTP response status as an integer
    def status
      Integer(http_status) rescue 0
    end

    # Length of content as an integer, or nil if chunked/unspecified
    def content_length
      @content_length ||= ((s = self[HttpClient::CONTENT_LENGTH]) &&
                           (s =~ /^(\d+)$/)) ? $1.to_i : nil
    end

    # Cookie header from the server
    def cookie
      self[HttpClient::SET_COOKIE]
    end

    # Is the transfer encoding chunked?
    def chunked_encoding?
      /chunked/i === self[HttpClient::TRANSFER_ENCODING]
    end

    def keep_alive?
      /keep-alive/i === self[HttpClient::KEEP_ALIVE]
    end

    def compressed?
      /gzip|compressed|deflate/i === self[HttpClient::CONTENT_ENCODING]
    end

    def location
      self[HttpClient::LOCATION]
    end
  end

  class HttpChunkHeader < Hash
    # When parsing chunked encodings this is set
    attr_accessor :http_chunk_size

    def initialize
      super
      @http_chunk_size = '0'
    end

    # Size of the chunk as an integer
    def chunk_size
      @http_chunk_size.to_i(base=16)
    end
  end

  # Methods for building HTTP requests
  module HttpEncoding
    HTTP_REQUEST_HEADER="%s %s HTTP/1.1\r\n"
    FIELD_ENCODING = "%s: %s\r\n"

    # Escapes a URI.
    def escape(s)
      s.to_s.gsub(/([^a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*bytesize($1)).join('%').upcase
      }
    end

    # Unescapes a URI escaped string.
    def unescape(s)
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
    end

    if ''.respond_to?(:bytesize)
      def bytesize(string)
        string.bytesize
      end
    else
      def bytesize(string)
        string.size
      end
    end

    # Map all header keys to a downcased string version
    def munge_header_keys(head)
      head.inject({}) { |h, (k, v)| h[k.to_s.downcase] = v; h }
    end

    # HTTP is kind of retarded that you have to specify a Host header, but if
    # you include port 80 then further redirects will tack on the :80 which is
    # annoying.
    def encode_host
      if @uri.port == 80 || @uri.port == 443
        return @uri.host
      else
        @uri.host + ":#{@uri.port}"
      end
    end

    def encode_request(method, uri, query, proxy)
      query = encode_query(uri, query)

      # Non CONNECT proxies require that you provide the full request
      # uri in request header, as opposed to a relative path.
      query = uri.join(query) if proxy && proxy[:type] != :socks && !proxy[:use_connect]

      HTTP_REQUEST_HEADER % [method.to_s.upcase, query]
    end

    def encode_query(uri, query)
      encoded_query = if query.kind_of?(Hash)
        query.map { |k, v| encode_param(k, v) }.join('&')
      else
        query.to_s
      end

      if !uri.query.to_s.empty?
        encoded_query = [encoded_query, uri.query].reject {|part| part.empty?}.join("&")
      end
      encoded_query.to_s.empty? ? uri.path : "#{uri.path}?#{encoded_query}"
    end

    # URL encodes query parameters:
    # single k=v, or a URL encoded array, if v is an array of values
    def encode_param(k, v)
      if v.is_a?(Array)
        v.map { |e| escape(k) + "[]=" + escape(e) }.join("&")
      else
        escape(k) + "=" + escape(v)
      end
    end

    def form_encode_body(obj)
      pairs = []
      recursive = Proc.new do |h, prefix|
        h.each do |k,v|
          key = prefix == '' ? escape(k) : "#{prefix}[#{escape(k)}]"

          if v.is_a? Array
            nh = Hash.new
            v.size.times { |t| nh[t] = v[t] }
            recursive.call(nh, key)

          elsif v.is_a? Hash
            recursive.call(v, key)
          else
            pairs << "#{key}=#{escape(v)}"
          end
        end
      end

      recursive.call(obj, '')
      return pairs.join('&')
    end

    # Encode a field in an HTTP header
    def encode_field(k, v)
      FIELD_ENCODING % [k, v]
    end

    # Encode basic auth in an HTTP header
    # In: Array ([user, pass]) - for basic auth
    #     String - custom auth string (OAuth, etc)
    def encode_auth(k,v)
      if v.is_a? Array
        FIELD_ENCODING % [k, ["Basic", Base64.encode64(v.join(":")).chomp].join(" ")]
      else
        encode_field(k,v)
      end
    end

    def encode_headers(head)
      head.inject('') do |result, (key, value)|
        # Munge keys from foo-bar-baz to Foo-Bar-Baz
        key = key.split('-').map { |k| k.to_s.capitalize }.join('-')
        result << case key
          when 'Authorization', 'Proxy-authorization'
            encode_auth(key, value)
          else
            encode_field(key, value)
        end
      end
    end

    def encode_cookie(cookie)
      if cookie.is_a? Hash
        cookie.inject('') { |result, (k, v)| result <<  encode_param(k, v) + ";" }
      else
        cookie
      end
    end
  end

  class HttpClient < Connection
    include EventMachine::Deferrable
    include HttpEncoding

    TRANSFER_ENCODING="TRANSFER_ENCODING"
    CONTENT_ENCODING="CONTENT_ENCODING"
    CONTENT_LENGTH="CONTENT_LENGTH"
    CONTENT_TYPE="CONTENT_TYPE".freeze
    LAST_MODIFIED="LAST_MODIFIED"
    KEEP_ALIVE="CONNECTION"
    SET_COOKIE="SET_COOKIE"
    LOCATION="LOCATION"
    HOST="HOST"
    ETAG="ETAG"

    CRLF="\r\n"

    attr_accessor :method, :options, :uri
    attr_reader   :response, :response_header, :error, :redirects, :last_effective_url, :content_charset

    def post_init
      @parser = HttpClientParser.new
      @data = EventMachine::Buffer.new
      @chunk_header = HttpChunkHeader.new
      @response_header = HttpResponseHeader.new
      @parser_nbytes = 0
      @redirects = 0
      @response = ''
      @error = ''
      @headers = nil
      @last_effective_url = nil
      @content_decoder = nil
      @content_charset = nil
      @stream = nil
      @disconnect = nil
      @state = :response_header
      @socks_state = nil
    end

    # start HTTP request once we establish connection to host
    def connection_completed
      # if a socks proxy is specified, then a connection request
      # has to be made to the socks server and we need to wait
      # for a response code
      if socks_proxy? and @state == :response_header
        @state = :connect_socks_proxy
        send_socks_handshake

        # if we need to negotiate the proxy connection first, then
        # issue a CONNECT query and wait for 200 response
      elsif connect_proxy? and @state == :response_header
        @state = :connect_http_proxy
        send_request_header

        # if connecting via proxy, then state will be :proxy_connected,
        # indicating successful tunnel. from here, initiate normal http
        # exchange

      else
        @state = :response_header
        ssl = @options[:tls] || @options[:ssl] || {}
        start_tls(ssl) if @uri.scheme == "https" or @uri.port == 443
        send_request_header
        send_request_body
      end
    end

    # request is done, invoke the callback
    def on_request_complete
      begin
        @content_decoder.finalize! if @content_decoder
      rescue HttpDecoders::DecoderError
        on_error "Content-decoder error"
      end

      close_connection
    end

    # request failed, invoke errback
    def on_error(msg, dns_error = false)
      @error = msg

      # no connection signature on DNS failures
      # fail the connection directly
      dns_error == true ? fail(self) : unbind
    end
    alias :close :on_error

    # assign a stream processing block
    def stream(&blk)
      @stream = blk
    end

    # assign disconnect callback for websocket
    def disconnect(&blk)
      @disconnect = blk
    end

    # assign a headers parse callback
    def headers(&blk)
      @headers = blk
    end

    # raw data push from the client (WebSocket) should
    # only be invoked after handshake, otherwise it will
    # inject data into the header exchange
    #
    # frames need to start with 0x00-0x7f byte and end with
    # an 0xFF byte. Per spec, we can also set the first
    # byte to a value betweent 0x80 and 0xFF, followed by
    # a leading length indicator
    def send(data)
      if @state == :websocket
        send_data("\x00#{data}\xff")
      end
    end

    def normalize_body
      @normalized_body ||= begin
        if @options[:body].is_a? Hash
          form_encode_body(@options[:body])
        else
          @options[:body]
        end
      end
    end

    # determines if there is enough data in the buffer
    def has_bytes?(num)
      @data.size >= num
    end

    def websocket?; @uri.scheme == 'ws'; end
    def proxy?; !@options[:proxy].nil?; end

    # determines if a proxy should be used that uses
    # http-headers as proxy-mechanism
    #
    # this is the default proxy type if none is specified
    def http_proxy?; proxy? && [nil, :http].include?(@options[:proxy][:type]); end

    # determines if a http-proxy should be used with
    # the CONNECT verb
    def connect_proxy?; http_proxy? && (@options[:proxy][:use_connect] == true); end

    # determines if a SOCKS5 proxy should be used
    def socks_proxy?; proxy? && (@options[:proxy][:type] == :socks); end

    def socks_methods
      methods = []
      methods << 2 if !options[:proxy][:authorization].nil? # 2 => Username/Password Authentication
      methods << 0 # 0 => No Authentication Required

      methods
    end

    def send_socks_handshake
      # Method Negotiation as described on
      # http://www.faqs.org/rfcs/rfc1928.html Section 3

      @socks_state = :method_negotiation

      methods = socks_methods
      send_data [5, methods.size].pack('CC') + methods.pack('C*')
    end

    def send_request_header
      query   = @options[:query]
      head    = @options[:head] ? munge_header_keys(@options[:head]) : {}
      file    = @options[:file]
      proxy   = @options[:proxy]
      body    = normalize_body

      request_header = nil

      if http_proxy?
        # initialize headers for the http proxy
        head = proxy[:head] ? munge_header_keys(proxy[:head]) : {}
        head['proxy-authorization'] = proxy[:authorization] if proxy[:authorization]

        # if we need to negotiate the tunnel connection first, then
        # issue a CONNECT query to the proxy first. This is an optional
        # flag, by default we will provide full URIs to the proxy
        if @state == :connect_http_proxy
          request_header = HTTP_REQUEST_HEADER % ['CONNECT', "#{@uri.host}:#{@uri.port}"]
        end
      end

      if websocket?
        head['upgrade'] = 'WebSocket'
        head['connection'] = 'Upgrade'
        head['origin'] = @options[:origin] || @uri.host

      else
        # Set the Content-Length if file is given
        head['content-length'] = File.size(file) if file

        # Set the Content-Length if body is given
        head['content-length'] =  body.bytesize if body

        # Set the cookie header if provided
        if cookie = head.delete('cookie')
          head['cookie'] = encode_cookie(cookie)
        end

        # Set content-type header if missing and body is a Ruby hash
        if not head['content-type'] and options[:body].is_a? Hash
          head['content-type'] = 'application/x-www-form-urlencoded'
        end

        # Set connection close unless keepalive
        unless options[:keepalive]
          head['connection'] = 'close'
        end
      end

      # Set the Host header if it hasn't been specified already
      head['host'] ||= encode_host

      # Set the User-Agent if it hasn't been specified
      head['user-agent'] ||= "EventMachine HttpClient"

      # Record last seen URL
      @last_effective_url = @uri

      # Build the request headers
      request_header ||= encode_request(@method, @uri, query, proxy)
      request_header << encode_headers(head)
      request_header << CRLF
      send_data request_header
    end

    def send_request_body
      if @options[:body]
        body = normalize_body
        send_data body
        return
      elsif @options[:file]
        stream_file_data @options[:file], :http_chunks => false
      end
    end

    def receive_data(data)
      @data << data
      dispatch
    end

    # Called when part of the body has been read
    def on_body_data(data)
      if @content_decoder
        begin
          @content_decoder << data
        rescue HttpDecoders::DecoderError
          on_error "Content-decoder error"
        end
      else
        on_decoded_body_data(data)
      end
    end

    def on_decoded_body_data(data)
      data.force_encoding @content_charset if @content_charset
      if @stream
        @stream.call(data)
      else
        @response << data
      end
    end

    def finished?
      @state == :finished || (@state == :body && @bytes_remaining.nil?)
    end

    def unbind
      if finished? && (@last_effective_url != @uri) && (@redirects < @options[:redirects])
        begin
          # update uri to redirect location if we're allowed to traverse deeper
          @uri = @last_effective_url

          # keep track of the depth of requests we made in this session
          @redirects += 1

          # swap current connection and reassign current handler
          req = HttpOptions.new(@method, @uri, @options)
          reconnect(req.host, req.port)

          @response_header = HttpResponseHeader.new
          @state = :response_header
          @response = ''
          @data.clear
        rescue EventMachine::ConnectionError => e
          on_error(e.message, true)
        end
      else
        if finished?
          succeed(self)
        else
          @disconnect.call(self) if @state == :websocket and @disconnect
          fail(self)
        end
      end
    end

    #
    # Response processing
    #

    def dispatch
      while case @state
          when :connect_socks_proxy
            parse_socks_response
          when :connect_http_proxy
            parse_response_header
          when :response_header
            parse_response_header
          when :chunk_header
            parse_chunk_header
          when :chunk_body
            process_chunk_body
          when :chunk_footer
            process_chunk_footer
          when :response_footer
            process_response_footer
          when :body
            process_body
          when :websocket
            process_websocket
          when :finished, :invalid
            break
          else raise RuntimeError, "invalid state: #{@state}"
        end
      end
    end

    def parse_header(header)
      return false if @data.empty?

      begin
        @parser_nbytes = @parser.execute(header, @data.to_str, @parser_nbytes)
      rescue EventMachine::HttpClientParserError
        @state = :invalid
        on_error "invalid HTTP format, parsing fails"
      end

      return false unless @parser.finished?

      # Clear parsed data from the buffer
      @data.read(@parser_nbytes)
      @parser.reset
      @parser_nbytes = 0

      true
    end

    def parse_response_header
      return false unless parse_header(@response_header)

      # invoke headers callback after full parse if one
      # is specified by the user
      @headers.call(@response_header) if @headers

      unless @response_header.http_status and @response_header.http_reason
        @state = :invalid
        on_error "no HTTP response"
        return false
      end

      if @state == :connect_http_proxy
        # when a successfull tunnel is established, the proxy responds with a
        # 200 response code. from here, the tunnel is transparent.
        if @response_header.http_status.to_i == 200
          @response_header = HttpResponseHeader.new
          connection_completed
          return true
        else
          @state = :invalid
          on_error "proxy not accessible"
          return false
        end
      end

      # correct location header - some servers will incorrectly give a relative URI
      if @response_header.location
        begin
          location = Addressable::URI.parse(@response_header.location)

          if location.relative?
            location = @uri.join(location)
            @response_header[LOCATION] = location.to_s
          else
            # if redirect is to an absolute url, check for correct URI structure
            raise if location.host.nil?
          end

          # store last url on any sign of redirect
          @last_effective_url = location

        rescue
          on_error "Location header format error"
          return false
        end
      end

      # Fire callbacks immediately after recieving header requests
      # if the request method is HEAD. In case of a redirect, terminate
      # current connection and reinitialize the process.
      if @method == "HEAD"
        @state = :finished
        close_connection
        return false
      end

      if websocket?
        if @response_header.status == 101
          @state = :websocket
          succeed
        else
          fail "websocket handshake failed"
        end

      elsif @response_header.chunked_encoding?
        @state = :chunk_header
      elsif @response_header.content_length
        @state = :body
        @bytes_remaining = @response_header.content_length
      else
        @state = :body
        @bytes_remaining = nil
      end

      if decoder_class = HttpDecoders.decoder_for_encoding(response_header[CONTENT_ENCODING])
        begin
          @content_decoder = decoder_class.new do |s| on_decoded_body_data(s) end
        rescue HttpDecoders::DecoderError
          on_error "Content-decoder error"
        end
      end

      if ''.respond_to?(:force_encoding) && /;\s*charset=\s*(.+?)\s*(;|$)/.match(response_header[CONTENT_TYPE])
        @content_charset = Encoding.find($1.gsub(/^\"|\"$/, '')) rescue Encoding.default_external
      end

      true
    end

    def send_socks_connect_request
      # TO-DO: Implement address types for IPv6 and Domain
      begin
        ip_address = Socket.gethostbyname(@uri.host).last
        send_data [5, 1, 0, 1, ip_address, @uri.port].flatten.pack('CCCCA4n')

      rescue
        @state = :invalid
        on_error "could not resolve host", true
        return false
      end

      true
    end

    # parses socks 5 server responses as specified
    # on http://www.faqs.org/rfcs/rfc1928.html
    def parse_socks_response
      if @socks_state == :method_negotiation
        return false unless has_bytes? 2

        _, method = @data.read(2).unpack('CC')

        if socks_methods.include?(method)
          if method == 0
            @socks_state = :connecting

            return send_socks_connect_request

          elsif method == 2
            @socks_state = :authenticating

            credentials = @options[:proxy][:authorization]
            if credentials.size < 2
              @state = :invalid
              on_error "username and password are not supplied"
              return false
            end

            username, password = credentials

            send_data [5, username.length, username, password.length, password].pack('CCA*CA*')
          end

        else
          @state = :invalid
          on_error "proxy did not accept method"
          return false
        end

      elsif @socks_state == :authenticating
        return false unless has_bytes? 2

        _, status_code = @data.read(2).unpack('CC')

        if status_code == 0
          # success
          @socks_state = :connecting

          return send_socks_connect_request

        else
          # error
          @state = :invalid
          on_error "access denied by proxy"
          return false
        end

      elsif @socks_state == :connecting
        return false unless has_bytes? 10

        _, response_code, _, address_type, _, _ = @data.read(10).unpack('CCCCNn')

        if response_code == 0
          # success
          @socks_state = :connected
          @state = :proxy_connected

          @response_header = HttpResponseHeader.new

          # connection_completed will invoke actions to
          # start sending all http data transparently
          # over the socks connection
          connection_completed

        else
          # error
          @state = :invalid

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
          on_error "socks5 connect error: #{error_message}"
          return false
        end
      end

      true
    end

    def parse_chunk_header
      return false unless parse_header(@chunk_header)

      @bytes_remaining = @chunk_header.chunk_size
      @chunk_header = HttpChunkHeader.new

      @state = @bytes_remaining > 0 ? :chunk_body : :response_footer
      true
    end

    def process_chunk_body
      if @data.size < @bytes_remaining
        @bytes_remaining -= @data.size
        on_body_data @data.read
        return false
      end

      on_body_data @data.read(@bytes_remaining)
      @bytes_remaining = 0

      @state = :chunk_footer
      true
    end

    def process_chunk_footer
      return false if @data.size < 2

      if @data.read(2) == CRLF
        @state = :chunk_header
      else
        @state = :invalid
        on_error "non-CRLF chunk footer"
      end

      true
    end

    def process_response_footer
      return false if @data.size < 2

      if @data.read(2) == CRLF
        if @data.empty?
          @state = :finished
          on_request_complete
        else
          @state = :invalid
          on_error "garbage at end of chunked response"
        end
      else
        @state = :invalid
        on_error "non-CRLF response footer"
      end

      false
    end

    def process_body
      if @bytes_remaining.nil?
        on_body_data @data.read
        return false
      end

      if @bytes_remaining.zero?
        @state = :finished
        on_request_complete
        return false
      end

      if @data.size < @bytes_remaining
        @bytes_remaining -= @data.size
        on_body_data @data.read
        return false
      end

      on_body_data @data.read(@bytes_remaining)
      @bytes_remaining = 0

      # If Keep-Alive is enabled, the server may be pushing more data to us
      # after the first request is complete. Hence, finish first request, and
      # reset state.
      if @response_header.keep_alive?
        @data.clear # hard reset, TODO: add support for keep-alive connections!
        @state = :finished
        on_request_complete

      else

        @data.clear
        @state = :finished
        on_request_complete
      end

      false
    end

    def process_websocket
      return false if @data.empty?

      # slice the message out of the buffer and pass in
      # for processing, and buffer data otherwise
      buffer = @data.read
      while msg = buffer.slice!(/\000([^\377]*)\377/n)
        msg.gsub!(/\A\x00|\xff\z/n, '')
        @stream.call(msg)
      end

      # store remainder if message boundary has not yet
      # been received
      @data << buffer if not buffer.empty?

      false
    end
  end

end
