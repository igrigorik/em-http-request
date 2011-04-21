class HttpClientOptions
  attr_reader :uri, :method, :host, :port, :proxy
  attr_reader :headers, :file, :body, :query
  attr_reader :keepalive, :redirects, :pass_cookies

  attr_accessor :followed

  def initialize(uri, options, method)
    set_uri(uri, options)

    @keepalive = options[:keepalive] || false  # default to single request per connection
    @redirects = options[:redirects] ||= 0     # default number of redirects to follow
    @followed  = options[:followed]  ||= 0     # keep track of number of followed requests

    @method   = method.to_s.upcase
    @headers  = options[:head]  || {}
    @proxy    = options[:proxy] || {}
    @query    = options[:query]

    @file     = options[:file]
    @body     = options[:body]

    @pass_cookies = options[:pass_cookies] || false
  end

  def follow_redirect?; @followed < @redirects; end
  def http_proxy?; @proxy && [nil, :http].include?(@proxy[:type]); end
  def ssl?; @uri.scheme == "https" || @uri.port == 443; end

  def set_uri(uri, options)
    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)

    uri.path = '/' if uri.path.empty?
    if path = options.delete(:path)
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

    if proxy = options[:proxy]
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = @uri.host
      @port = @uri.port
    end

  end
end
