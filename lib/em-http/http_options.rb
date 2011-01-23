class HttpOptions
  attr_reader :uri, :method, :host, :port, :options

  def initialize(uri, options, method = :none)
    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    uri.path = '/' if uri.path.empty?

    @options = options
    @method = method.to_s.upcase
    @uri = uri

    if proxy = options[:proxy]
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = uri.host
      @port = uri.port
    end

    @options[:timeout]    ||= 10    # default connect & inactivity timeouts
    @options[:redirects]  ||= 0     # default number of redirects to follow
    @options[:keepalive]  ||= false # default to single request per connection

    # Make sure the ports are set as Addressable::URI doesn't
    # set the port if it isn't there
    if uri.scheme == "https"
      @uri.port ||= 443
      @port     ||= 443
    else
      @uri.port ||= 80
      @port     ||= 80
    end
  end
end