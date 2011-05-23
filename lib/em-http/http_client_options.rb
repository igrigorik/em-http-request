class HttpClientOptions
  attr_reader :uri, :method, :host, :port, :proxy
  attr_reader :headers, :file, :body, :query, :path
  attr_reader :keepalive, :pass_cookies, :decoding

  attr_accessor :followed, :redirects

  def initialize(uri, options, method)
    @keepalive = options[:keepalive] || false  # default to single request per connection
    @redirects = options[:redirects] ||= 0     # default number of redirects to follow
    @followed  = options[:followed]  ||= 0     # keep track of number of followed requests

    @method   = method.to_s.upcase
    @headers  = options[:head]  || {}
    @proxy    = options[:proxy] || {}
    @query    = options[:query]
    @path     = options[:path]

    @file     = options[:file]
    @body     = options[:body]

    @pass_cookies = options.fetch(:pass_cookies, true)  # pass cookies between redirects
    @decoding     = options.fetch(:decoding, true)      # auto-decode compressed response

    set_uri(uri)
  end

  def follow_redirect?; @followed < @redirects; end
  def http_proxy?; @proxy && [nil, :http].include?(@proxy[:type]); end
  def ssl?; @uri.scheme == "https" || @uri.port == 443; end

  def set_uri(uri)
    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    uri.path = '/' if uri.path.empty?
    uri.path = @path if @path

    @uri = uri

    # Make sure the ports are set as Addressable::URI doesn't
    # set the port if it isn't there
    if @uri.scheme == "https"
      @uri.port ||= 443
    else
      @uri.port ||= 80
    end

    if !@proxy.empty?
      @host = @proxy[:host]
      @port = @proxy[:port]
    else
      @host = @uri.host
      @port = @uri.port
    end

  end
end