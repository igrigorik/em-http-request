module EventMachine
  module HttpEncoding
    HTTP_REQUEST_HEADER="%s %s HTTP/1.1\r\n"
    FIELD_ENCODING = "%s: %s\r\n"

    # Escapes a URI.
    def escape(s)
      EscapeUtils.escape_url(s.to_s)
    end

    # Unescapes a URI escaped string.
    def unescape(s)
      EscapeUtils.unescape_url(s.to_s)
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
        FIELD_ENCODING % [k, ["Basic", Base64.encode64(v.join(":")).split.join].join(" ")]
      else
        encode_field(k,v)
      end
    end

    def encode_headers(head)
      head.inject('') do |result, (key, value)|
        # Munge keys from foo-bar-baz to Foo-Bar-Baz
        key = key.split('-').map { |k| k.to_s.capitalize }.join('-')
        result << case key
          when 'Authorization', 'Proxy-Authorization'
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
end
