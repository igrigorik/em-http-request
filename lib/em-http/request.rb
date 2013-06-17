module EventMachine
  class HttpRequest
    @middleware = []

    def self.new(uri, options={})
      uri = uri.clone
      connopt = HttpConnectionOptions.new(uri, options)

      c = HttpConnection.new
      c.connopts = connopt
      c.uri = uri
      c
    end

    def self.use(klass, *args, &block)
      @middleware << klass.new(*args, &block)
    end

    def self.middleware
      @middleware
    end
  end
end
