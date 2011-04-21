class HttpConnectionOptions
  attr_reader :host, :port, :tls, :proxy
  attr_reader :connect_timeout, :inactivity_timeout

  def initialize(uri, options)
    @connect_timeout     = options[:connect_timeout] || 5        # default connection setup timeout
    @inactivity_timeout  = options[:inactivity_timeout] ||= 10   # default connection inactivity (post-setup) timeout

    @tls   = options[:tls] || options[:ssl] || {}
    @proxy = options[:proxy]

    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    uri.port = (uri.scheme == "https" ? (uri.port || 443) : (uri.port || 80))

    if proxy = options[:proxy]
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = uri.host
      @port = uri.port
    end
  end
end
