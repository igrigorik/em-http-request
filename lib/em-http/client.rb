require 'cookiejar'

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

    attr_accessor :state, :response, :conn
    attr_reader   :response_header, :error, :content_charset, :req, :cookies

    def initialize(conn, options)
      @conn = conn
      @req  = options

      @stream    = nil
      @headers   = nil
      @cookies   = []
      @cookiejar = CookieJar.new

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
      @response_header.redirection? && @req.follow_redirect?
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

              @cookies.clear
              @cookies = @cookiejar.get(@response_header.location).map(&:to_s) if @req.pass_cookies

              @conn.redirect(self, @response_header.location)
            else
              succeed(self)
            end

          rescue => e
            on_error(e.message)
          end
        else
          succeed(self)
        end

      else
        on_error(reason || 'connection closed by server')
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

      if @conn.connopts.http_proxy?
        proxy = @conn.connopts.proxy
        head['proxy-authorization'] = proxy[:authorization] if proxy[:authorization]
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
      if !head.key?('user-agent')
        head['user-agent'] = 'EventMachine HttpClient'
      elsif head['user-agent'].nil?
        head.delete('user-agent')
      end

      # Set the Accept-Encoding header if none is provided
      if !head.key?('accept-encoding') && req.compressed
        head['accept-encoding'] = 'gzip, compressed'
      end

      # Set the auth from the URI if given
      head['Authorization'] = @req.uri.userinfo.split(/:/, 2) if @req.uri.userinfo

      head
    end

    def send_request(head, body)
      body    = normalize_body(body)
      file    = @req.file
      query   = @req.query

      # Set the Content-Length if file is given
      head['content-length'] = File.size(file) if file

      # Set the Content-Length if body is given,
      # or we're doing an empty post or put
      if body
        head['content-length'] = body.bytesize
      elsif @req.method == 'POST' or @req.method == 'PUT'
        # wont happen if body is set and we already set content-length above
        head['content-length'] ||= 0
      end

      # Set content-type header if missing and body is a Ruby hash
      if !head['content-type'] and @req.body.is_a? Hash
        head['content-type'] = 'application/x-www-form-urlencoded'
      end

      request_header ||= encode_request(@req.method, @req.uri, query, @conn.connopts)
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
      @response_header.raw = header
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
      if @response_header.cookie && @req.pass_cookies
        [@response_header.cookie].flatten.each {|cookie| @cookiejar.set(cookie, @req.uri)}
      end

      # correct location header - some servers will incorrectly give a relative URI
      if @response_header.location
        begin
          location = Addressable::URI.parse(@response_header.location)
          location.path = "/" if location.path.empty?

          if location.relative?
            location = @req.uri.join(location)
          else
            # if redirect is to an absolute url, check for correct URI structure
            raise if location.host.nil?
          end

          @response_header[LOCATION] = location.to_s

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

      # handle malformed header - Content-Type repetitions.
      content_type = [response_header[CONTENT_TYPE]].flatten.first

      if String.method_defined?(:force_encoding) && /;\s*charset=\s*(.+?)\s*(;|$)/.match(content_type)
        @content_charset = Encoding.find($1.gsub(/^\"|\"$/, '')) rescue Encoding.default_external
      end
    end

    class CookieJar
      def initialize
        @jar = ::CookieJar::Jar.new
      end

      def set string, uri
        @jar.set_cookie(uri, string) rescue nil # drop invalid cookies
      end

      def get uri
        uri = URI.parse(uri) rescue nil
        uri ? @jar.get_cookies(uri) : []
      end
    end # CookieJar
  end
end
