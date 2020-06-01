class HttpConnectionOptions
  attr_reader :host, :port, :tls, :proxy, :bind, :bind_port
  attr_reader :connect_timeout, :inactivity_timeout
  attr_writer :https

  def initialize(uri, options)
    @connect_timeout     = options[:connect_timeout] || 5        # default connection setup timeout
    @inactivity_timeout  = options[:inactivity_timeout] ||= 10   # default connection inactivity (post-setup) timeout

    @tls   = options[:tls] || options[:ssl] || {}

    if bind = options[:bind]
      @bind = bind[:host] || '0.0.0.0'

      # Eventmachine will open a UNIX socket if bind :port
      # is explicitly set to nil
      @bind_port = bind[:port]
    end

    uri = uri.kind_of?(Addressable::URI) ? uri : Addressable::URI::parse(uri.to_s)
    @https = uri.scheme == "https"
    uri.port ||= (@https ? 443 : 80)
    @tls[:sni_hostname] = uri.hostname

    @proxy = options[:proxy] || proxy_from_env

    if proxy
      @host = proxy[:host]
      @port = proxy[:port]
    else
      @host = uri.hostname
      @port = uri.port
    end
  end

  def http_proxy?
    @proxy && (@proxy[:type] == :http || @proxy[:type].nil?) && !@https
  end

  def connect_proxy?
    @proxy && (@proxy[:type] == :http || @proxy[:type].nil?) && @https
  end

  def socks_proxy?
    @proxy && (@proxy[:type] == :socks5)
  end

  def proxy_from_env
    # TODO: Add support for $http_no_proxy or $no_proxy ?
    proxy_str = if @https
                  ENV['HTTPS_PROXY'] || ENV['https_proxy']
                else
                  ENV['HTTP_PROXY'] || ENV['http_proxy']

                # Fall-back to $ALL_PROXY if none of the above env-vars have values
                end || ENV['ALL_PROXY']

    # Addressable::URI::parse will return `nil` if given `nil` and an empty URL for an empty string
    # so, let's short-circuit that:
    return if !proxy_str || proxy_str.empty?

    proxy_env_uri = Addressable::URI::parse(proxy_str)
    { :host => proxy_env_uri.host, :port => proxy_env_uri.port, :type => :http }

  rescue Addressable::URI::InvalidURIError
    # An invalid env-var shouldn't crash the config step, IMHO.
    # We should somehow log / warn about this, perhaps...
    return
  end
end
