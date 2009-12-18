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
      self["ETag"]
    end
    
    def last_modified
      time = self["Last-Modified"]
      Time.parse(time) if time
    end

    # HTTP response status as an integer
    def status
      Integer(http_status) rescue nil
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

    # Size of the chunk as an integer
    def chunk_size
      return @chunk_size unless @chunk_size.nil?
      @chunk_size = @http_chunk_size ? @http_chunk_size.to_i(base=16) : 0
    end
  end

  # Methods for building HTTP requests
  module HttpEncoding
    HTTP_REQUEST_HEADER="%s %s HTTP/1.1\r\n"
    FIELD_ENCODING = "%s: %s\r\n"

    # Escapes a URI.
    def escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      }.tr(' ', '+')
    end

    # Unescapes a URI escaped string.
    def unescape(s)
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
    end

    # Map all header keys to a downcased string version
    def munge_header_keys(head)
      head.inject({}) { |h, (k, v)| h[k.to_s.downcase] = v; h }
    end

    # HTTP is kind of retarded that you have to specify a Host header, but if
    # you include port 80 then further redirects will tack on the :80 which is
    # annoying.
    def encode_host
      @uri.host + (@uri.port != 80 ? ":#{@uri.port}" : "")
    end

    def encode_request(method, path, query, uri_query)
      HTTP_REQUEST_HEADER % [method.to_s.upcase, encode_query(path, query, uri_query)]
    end

    def encode_query(path, query, uri_query)
      encoded_query = if query.kind_of?(Hash)
        query.map { |k, v| encode_param(k, v) }.join('&')
      else
        query.to_s
      end
      if !uri_query.to_s.empty?
        encoded_query = [encoded_query, uri_query].reject {|part| part.empty?}.join("&")
      end
      return path if encoded_query.to_s.empty?
      "#{path}?#{encoded_query}"
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
    KEEP_ALIVE="CONNECTION"
    SET_COOKIE="SET_COOKIE"
    LOCATION="LOCATION"
    HOST="HOST"
    CRLF="\r\n"

    attr_accessor :method, :options, :uri
    attr_reader   :response, :response_header, :errors

    def post_init
      @parser = HttpClientParser.new
      @data = EventMachine::Buffer.new
      @chunk_header = HttpChunkHeader.new
      @response_header = HttpResponseHeader.new
      @parser_nbytes = 0
      @response = ''
      @errors = ''
      @content_decoder = nil
      @stream = nil
      @state = :response_header
    end

    # start HTTP request once we establish connection to host
    def connection_completed              
      # if connecting to proxy, then first negotiate the connection
      # to intermediate server and wait for 200 response 
      if @options[:proxy] and @state == :response_header 
        @state = :response_proxy
        send_request_header
        
        # if connecting via proxy, then state will be :proxy_connected,
        # indicating successful tunnel. from here, initiate normal http
        # exchange
      elsif @uri.scheme == 'ws'
        @state = :response_header # TODO: refactor
        puts "WebSocket!"
        send_request_header
        
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
      unbind
    end
    
    # request failed, invoke errback
    def on_error(msg, dns_error = false)
      @errors = msg
      
      # no connection signature on DNS failures
      # fail the connection directly
      dns_error == true ? fail(self) : unbind
    end

    # assign a stream processing block
    def stream(&blk)
      @stream = blk
    end

    # raw data push from the client (WebSocket)
    def push(data)
      p "\x00#{data}\xff"
      send_data "\x00#{data}\xff"
    end

    def normalize_body
      if @options[:body].is_a? Hash
        @options[:body].to_params
      else
        @options[:body]
      end
    end
                  
    def send_request_header
      query   = @options[:query]
      head    = @options[:head] ? munge_header_keys(@options[:head]) : {}
      body    = normalize_body
      request_header = nil

      if @state == :response_proxy
        proxy = @options[:proxy]

        # initialize headers to establish the HTTP tunnel
        head = proxy[:head] ? munge_header_keys(proxy[:head]) : {}
        head['proxy-authorization'] = proxy[:authorization] if proxy[:authorization]
        request_header = HTTP_REQUEST_HEADER % ['CONNECT', "#{@uri.host}:#{@uri.port}"]
        
      elsif @uri.scheme == 'ws'
        head['upgrade'] = 'WebSocket'
        head['connection'] = 'Upgrade'
        head['origin'] = @uri.host # TODO: verify? override with params[:origin] ???
        
      else
        # Set the Content-Length if body is given
        head['content-length'] =  body.length if body

        # Set the cookie header if provided
        if cookie = head.delete('cookie')
          head['cookie'] = encode_cookie(cookie)
        end

        # Set content-type header if missing and body is a Ruby hash
        if not head['content-type'] and options[:body].is_a? Hash
          head['content-type'] = "application/x-www-form-urlencoded"
        end
      end

       # Set the Host header if it hasn't been specified already
      head['host'] ||= encode_host

      # Set the User-Agent if it hasn't been specified
      head['user-agent'] ||= "EventMachine HttpClient"

      # Build the request headers
      request_header ||= encode_request(@method, @uri.path, query, @uri.query)
      request_header << encode_headers(head)
      request_header << CRLF
      send_data request_header
    end

    def send_request_body
      return unless @options[:body]
      body = normalize_body
      send_data body
    end

    def receive_data(data)
      p "got: #{data.inspect}"
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
      if @stream
        @stream.call(data)
      else
        @response << data
      end
    end

    def unbind
      if @state == :finished || (@state == :body && @bytes_remaining.nil?)
        succeed(self)
      else
        fail(self)
      end
      close_connection
    end

    #
    # Response processing
    #

    def dispatch
      while case @state
        when :response_proxy
          parse_response_proxy
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
    
    # TODO: refactor with parse_response_header
    def parse_response_proxy
      return false unless parse_header(@response_header)

      unless @response_header.http_status and @response_header.http_reason
        @state = :invalid
        on_error "no HTTP response"
        return false
      end
          
      # when a successfull tunnel is established, the proxy responds with a
      # 200 response code. from here, the tunnel is transparent.
      if @response_header.http_status.to_i == 200
        @response_header = HttpResponseHeader.new
        connection_completed
      else
        @state = :invalid
        on_error "proxy not accessible"
        return false
      end
    end

    def parse_response_header
      return false unless parse_header(@response_header)

      unless @response_header.http_status and @response_header.http_reason
        @state = :invalid
        on_error "no HTTP response"
        return false
      end

      # correct location header - some servers will incorrectly give a relative URI
      if @response_header.location
        begin
          location = Addressable::URI.parse @response_header.location
          if location.relative?
            location = (@uri.join location).to_s
            @response_header[LOCATION] = location
          end
        rescue
          on_error "Location header format error"
          return false
        end
      end

      # shortcircuit on HEAD requests
      if @method == "HEAD"
        @state = :finished
        on_request_complete
      end

      if @response_header.chunked_encoding?
        @state = :chunk_header
      elsif @response_header.content_length
        @state = :body
        @bytes_remaining = @response_header.content_length
        
      elsif @uri.scheme == 'ws'
        if @response_header.status == 101
          # @state = :websocket
          # p @data.to_str
          # p @data.clear
          
          push "wtfffff"
          @state = :websocket
          # succeed
          puts 'setting state to :websocket'
        else
          fail "WebSocket handshake failed"
        end
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
        if @data.empty?
          @state = :finished
          on_request_complete
        else
          @state = :invalid
          on_error "garbage at end of body"
        end
      end

      false
    end

    def process_websocket
       @response << @data
       @stream.call(@data)
       @response = ''
       @data.clear
        # if @response_header.status == 101 
          # push ("test")
          # sleep(1)
          # succeed(self)
        # else
          # fail(self)
        # end
    end
  
  end

end
