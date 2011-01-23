class HttpOptions
  attr_reader :uri, :method, :host, :port, :options

  def initialize(uri, options, method = :none)
    @options = options
    @method = method.to_s.upcase

    set_uri(uri)

    @options[:keepalive]  ||= false # default to single request per connection
    @options[:timeout]    ||= 10    # default connect & inactivity timeouts
    @options[:redirects]  ||= 0     # default number of redirects to follow
    @options[:followed]   ||= 0     # keep track of number of followed requests
  end

  def proxy
    @options[:proxy]
  end

  def follow_redirect?
    @options[:followed] < @options[:redirects]
  end

  def set_uri(uri)
    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)

    uri.path = '/' if uri.path.empty?
    if path = @options.delete(:path)
      uri.path = path
    end

    @uri = uri

    # Make sure the ports are set as Addressable::URI doesn't
    # set the port if it isn't there
    if @uri.scheme == "https"
      @uri.port ||= 443
    else
      @uri.port ||= 80
    end

    if proxy = @options[:proxy]
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = @uri.host
      @port = @uri.port
    end

  end
end