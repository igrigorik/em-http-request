module EventMachine

  class HttpClient
    include Deferrable
    include HttpEncoding
    include HttpStatus

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

    attr_accessor :state, :response
    attr_reader   :response_header, :error, :content_charset, :req, :cookies

    def initialize(conn, options)
      @conn = conn
      @req  = options

      @stream = nil
      @headers = nil
      @cookies = []

      reset!
    end

    def reset!
      @response_header = HttpResponseHeader.new
      @state = :response_header

      @response = ''
      @error = nil
      @content_decoder = nil
      @content_charset = nil
    end

    def last_effective_url; @req.uri; end
    def redirects; @req.followed; end
    def peer; @conn.peer; end

    def connection_completed
      @state = :response_header

      head, body = build_request, @req.body
      @conn.middleware.each do |m|
        head, body = m.request(self, head, body) if m.respond_to?(:request)
      end

      send_request(head, body)
    end

    def on_request_complete
      begin
        @content_decoder.finalize! if @content_decoder
      rescue HttpDecoders::DecoderError
        on_error "Content-decoder error"
      end

      unbind
    end

    def continue?
      @response_header.status == 100 && (@req.method == 'POST' || @req.method == 'PUT')
    end

    def finished?
      @state == :finished || (@state == :body && @response_header.content_length.nil?)
    end

    def redirect?
      @response_header.location && @req.follow_redirect?
    end

    def unbind(reason = nil)
      if finished?
        if redirect?

          begin
            @conn.middleware.each do |m|
              m.response(self) if m.respond_to?(:response)
            end

            # one of the injected middlewares could have changed
            # our redirect settings, check if we still want to
            # follow the location header
            if redirect?
              @req.followed += 1
              @req.set_uri(@response_header.location)
              @conn.redirect(self)
            else
              succeed(self)
            end

          rescue Exception => e
            on_error(e.message)
          end
        else
          succeed(self)
        end

      else
        on_error(reason)
      end
    end

    def on_error(msg = nil)
      @error = msg
      fail(self)
    end
    alias :close :on_error

    def stream(&blk); @stream = blk; end
    def headers(&blk); @headers = blk; end

    def normalize_body(body)
      body.is_a?(Hash) ? form_encode_body(body) : body
    end

    def build_request
      head    = @req.headers ? munge_header_keys(@req.headers) : {}
      proxy   = @req.proxy

      if @req.http_proxy?
        head['proxy-authorization'] = @req.proxy[:authorization] if @req.proxy[:authorization]
      end

      # Set the cookie header if provided
      if cookie = head['cookie']
        @cookies << encode_cookie(cookie) if cookie
      end
      head['cookie'] = @cookies.compact.uniq.join("; ").squeeze(";") unless @cookies.empty?

      # Set connection close unless keepalive
      if !@req.keepalive
        head['connection'] = 'close'
      end

      # Set the Host header if it hasn't been specified already
      head['host'] ||= encode_host

      # Set the User-Agent if it hasn't been specified
      head['user-agent'] ||= "EventMachine HttpClient"

      head
    end

    def send_request(head, body)
      body    = normalize_body(body)
      file    = @req.file
      query   = @req.query

      # Set the Content-Length if file is given
      head['content-length'] = File.size(file) if file

      # Set the Content-Length if body is given
      head['content-length'] =  body.bytesize if body

      # Set content-type header if missing and body is a Ruby hash
      if not head['content-type'] and @req.body.is_a? Hash
        head['content-type'] = 'application/x-www-form-urlencoded'
      end

      request_header ||= encode_request(@req.method, @req.uri, query, @conn.connopts.proxy)
      request_header << encode_headers(head)
      request_header << CRLF
      @conn.send_data request_header

      if body
        @conn.send_data body
      elsif @req.file
        @conn.stream_file_data @req.file, :http_chunks => false
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

    def parse_response_header(header, version, status)
      header.each do |key, val|
        @response_header[key.upcase.gsub('-','_')] = val
      end

      @response_header.http_version = version.join('.')
      @response_header.http_status  = status
      @response_header.http_reason  = CODE[status] || 'unknown'

      # invoke headers callback after full parse
      # if one is specified by the user
      @headers.call(@response_header) if @headers

      unless @response_header.http_status and @response_header.http_reason
        @state = :invalid
        on_error "no HTTP response"
        return
      end

      # add set-cookie's to cookie list
      @cookies << @response_header.cookie if @response_header.cookie && @req.pass_cookies

      # correct location header - some servers will incorrectly give a relative URI
      if @response_header.location
        begin
          location = Addressable::URI.parse(@response_header.location)

          if location.relative?
            location = @req.uri.join(location)
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
      if @req.method == "HEAD"
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

      if @req.decoding && decoder_class = HttpDecoders.decoder_for_encoding(response_header[CONTENT_ENCODING])
        begin
          @content_decoder = decoder_class.new do |s| on_decoded_body_data(s) end
        rescue HttpDecoders::DecoderError
          on_error "Content-decoder error"
        end
      end

      if String.method_defined?(:force_encoding) && /;\s*charset=\s*(.+?)\s*(;|$)/.match(response_header[CONTENT_TYPE])
        @content_charset = Encoding.find($1.gsub(/^\"|\"$/, '')) rescue Encoding.default_external
      end
    end

  end
end
