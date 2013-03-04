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

    # Raw headers
    attr_accessor :raw

    # E-Tag
    def etag
      self[HttpClient::ETAG]
    end

    def last_modified
      self[HttpClient::LAST_MODIFIED]
    end

    # HTTP response status as an integer
    def status
      @status ||= Integer(http_status) rescue 0
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

    def keepalive?
      /keep-alive/i === self[HttpClient::KEEP_ALIVE]
    end

    def compressed?
      /gzip|compressed|deflate/i === self[HttpClient::CONTENT_ENCODING]
    end

    def location
      self[HttpClient::LOCATION]
    end

    def [](key)
      super(key) || super(key.upcase.gsub('-','_'))
    end

    def informational?
      100 <= status && 200 > status
    end

    def successful?
      200 <= status && 300 > status
    end

    def redirection?
      300 <= status && 400 > status
    end

    def client_error?
      400 <= status && 500 > status
    end

    def server_error?
      500 <= status && 600 > status
    end
  end
end
