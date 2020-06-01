class HttpClientOptions
  attr_reader :uri, :method, :host, :port
  attr_reader :headers, :file, :body, :query, :path
  attr_reader :keepalive, :pass_cookies, :decoding, :compressed

  attr_accessor :followed, :redirects

  def initialize(uri, options, method)
    @keepalive = options[:keepalive] || false  # default to single request per connection
    @redirects = options[:redirects] ||= 0     # default number of redirects to follow
    @followed  = options[:followed]  ||= 0     # keep track of number of followed requests

    @method   = method.to_s.upcase
    @headers  = options[:head] || {}

    @file     = options[:file]
    @body     = options[:body]

    @pass_cookies = options.fetch(:pass_cookies, true)  # pass cookies between redirects
    @decoding     = options.fetch(:decoding, true)      # auto-decode compressed response
    @compressed   = options.fetch(:compressed, true)    # auto-negotiated compressed response

    set_uri(uri, options[:path], options[:query])
  end

  def follow_redirect?; @followed < @redirects; end
  def ssl?; @uri.scheme == "https" || @uri.port == 443; end
  def no_body?; @method == "HEAD"; end

  def set_uri(uri, path = nil, query = nil)
    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    uri.path = path if path
    uri.path = '/' if uri.path.empty?

    @uri = uri
    @path = uri.path
    @host = uri.hostname
    @port = uri.port
    @query = query

    # Make sure the ports are set as Addressable::URI doesn't
    # set the port if it isn't there
    if @port.nil?
      @port = @uri.scheme == "https" ? 443 : 80
    end

    uri
  end
end
