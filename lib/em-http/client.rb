module EventMachine
  class HttpClient
    include EventMachine::Deferrable
    include EventMachine::HttpEncoding

    TRANSFER_ENCODING="TRANSFER_ENCODING"
    CONTENT_ENCODING="CONTENT_ENCODING"
    CONTENT_LENGTH="CONTENT_LENGTH"
    CONTENT_TYPE="CONTENT_TYPE"
    LAST_MODIFIED="LAST_MODIFIED"
    KEEP_ALIVE="CONNECTION"
    SET_COOKIE="SET_COOKIE"
    LOCATION="LOCATION"
    HOST="HOST"
    ETAG="ETAG"

    CRLF="\r\n"

    attr_accessor :state
    attr_reader   :response, :response_header, :error, :redirects, :content_charset

    def initialize(conn, req, options)
      @conn = conn

      @req = req
      @uri = req.uri
      @method = req.method
      @options = options

      @response_header = HttpResponseHeader.new

      @response = ''
      @error = ''
      @content_decoder = nil
      @content_charset = nil

      @stream = nil
      @headers = nil

      @state = :response_header
    end

    def connection_completed
      @state = :response_header
      send_request_header
      send_request_body
    end

    def on_request_complete
      begin
        @content_decoder.finalize! if @content_decoder
      rescue HttpDecoders::DecoderError
        on_error "Content-decoder error"
      end

      succeed
    end

    def on_error(msg)
      @error = msg
      fail(self)
    end
    alias :close :on_error

    def stream(&blk); @stream = blk; end
    def headers(&blk); @headers = blk; end

    def normalize_body
      @normalized_body ||= begin
        if @options[:body].is_a? Hash
          form_encode_body(@options[:body])
        else
          @options[:body]
        end
      end
    end

    def proxy?; !@options[:proxy].nil?; end

    # determines if a proxy should be used that uses
    # http-headers as proxy-mechanism
    #
    # this is the default proxy type if none is specified
    def http_proxy?; proxy? && [nil, :http].include?(@options[:proxy][:type]); end

    # determines if a SOCKS5 proxy should be used
    def socks_proxy?; proxy? && (@options[:proxy][:type] == :socks); end

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
      end

      # Set the Content-Length if file is given
      head['content-length'] = File.size(file) if file

      # Set the Content-Length if body is given
      head['content-length'] =  body.bytesize if body

      # Set the cookie header if provided
      if cookie = head.delete('cookie')
        head['cookie'] = encode_cookie(cookie)
      end

      # Set content-type header if missing and body is a Ruby hash
      if not head['content-type'] and @options[:body].is_a? Hash
        head['content-type'] = 'application/x-www-form-urlencoded'
      end

      # Set connection close unless keepalive
      unless @options[:keepalive]
        head['connection'] = 'close'
      end

      # Set the Host header if it hasn't been specified already
      head['host'] ||= encode_host

      # Set the User-Agent if it hasn't been specified
      head['user-agent'] ||= "EventMachine HttpClient"

      # Build the request headers
      request_header ||= encode_request(@method, @uri, query, proxy)
      request_header << encode_headers(head)
      request_header << CRLF
      @conn.send_data request_header
    end

    def send_request_body
      if @options[:body]
        body = normalize_body
        @conn.send_data body
        return
      elsif @options[:file]
        @conn.stream_file_data @options[:file], :http_chunks => false
      end
    end

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
      @state == :finished || (@state == :body && @response_header.content_length.nil?)
    end

    def unbind
      succeed if finished?
      fail
    end

    def parse_response_header(header, version, status)
      header.each do |key, val|
        @response_header[key.upcase.gsub('-','_')] = val
      end

      @response_header.http_version = version.join('.')
      @response_header.http_status  = status
      @response_header.http_reason  = 'unknown'

      # invoke headers callback after full parse
      # if one is specified by the user
      @headers.call(@response_header) if @headers

      unless @response_header.http_status and @response_header.http_reason
        @state = :invalid
        on_error "no HTTP response"
        return
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

        rescue
          on_error "Location header format error"
          return
        end
      end

      # Fire callbacks immediately after recieving header requests
      # if the request method is HEAD. In case of a redirect, terminate
      # current connection and reinitialize the process.
      if @method == "HEAD"
        @state = :finished
        return
      end

      if @response_header.chunked_encoding?
        @state = :chunk_header
      elsif @response_header.content_length
        @state = :body
      else
        @state = :body
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
    end

  end
end
