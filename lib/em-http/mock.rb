module EventMachine
  OriginalHttpRequest = HttpRequest unless const_defined?(:OriginalHttpRequest)

  class MockHttpRequest < EventMachine::HttpRequest

    include HttpEncoding

    class RegisteredRequest < Struct.new(:uri, :method, :headers)
      def self.build(uri, method, headers)
        new(uri, method.to_s.upcase, headers || {})
      end
    end

    class FakeHttpClient < EventMachine::HttpClient
      attr_writer :response
      attr_reader :data
      def setup(response, uri)
        @uri = uri
        if response == :fail
          fail(self)
        else
          if response.respond_to?(:call)
            response.call(self)
            @state = :body
          else
            receive_data(response)
          end
          @state == :body ? succeed(self) : fail(self)
        end
      end

      def unbind
      end
    end

    @@registry = Hash.new
    @@registry_count = Hash.new{|h,k| h[k] = 0}

    def self.use
      activate!
      yield
    ensure
      deactivate!
    end

    def self.activate!
      EventMachine.send(:remove_const, :HttpRequest)
      EventMachine.send(:const_set, :HttpRequest, MockHttpRequest)
    end

    def self.deactivate!
      EventMachine.send(:remove_const, :HttpRequest)
      EventMachine.send(:const_set, :HttpRequest, OriginalHttpRequest)
    end

    def self.reset_counts!
      @@registry_count.clear
    end

    def self.reset_registry!
      @@registry.clear
    end

    @@pass_through_requests = true

    def self.pass_through_requests=(pass_through_requests)
      @@pass_through_requests = pass_through_requests
    end

    def self.pass_through_requests
      @@pass_through_requests
    end

    def self.parse_register_args(args, &proc)
      args << proc{|client| proc.call(client); ''} if proc
      headers, data = case args.size
      when 3
        args[2].is_a?(Hash) ?
          [args[2][:headers], args[2][:data]] :
          [{}, args[2]]
      when 4
        [args[2], args[3]]
      else
        raise
      end

      url = args[0]
      method = args[1]
      [headers, url, method, data]
    end

    def self.register(*args, &proc)
      headers, url, method, data = parse_register_args(args, &proc)
      @@registry[RegisteredRequest.build(url, method, headers)] = data
    end

    def self.register_file(*args)
      headers, url, method, data = parse_register_args(args)
      @@registry[RegisteredRequest.build(url, method, headers)] = File.read(data)
    end

    def self.count(url, method, headers = {})
      @@registry_count[RegisteredRequest.build(url, method, headers)]
    end

    def self.registered?(url, method, headers = {})
      @@registry.key?(RegisteredRequest.build(url, method, headers))
    end

    def self.registered_content(url, method, headers = {})
      @@registry[RegisteredRequest.build(url, method, headers)]
    end

    def self.increment_access(url, method, headers = {})
      @@registry_count[RegisteredRequest.build(url, method, headers)] += 1
    end

    alias_method :real_send_request, :send_request

    protected
    def send_request(&blk)
      query = "#{@req.uri.scheme}://#{@req.uri.host}:#{@req.uri.port}#{encode_query(@req.uri, @req.options[:query])}"
      headers = @req.options[:head]
      if self.class.registered?(query, @req.method, headers)
        self.class.increment_access(query, @req.method, headers)
        client = FakeHttpClient.new(nil)
        content = self.class.registered_content(query, @req.method, headers)
        client.setup(content, @req.uri)
        client
      elsif @@pass_through_requests
        real_send_request
      else
        raise "this request #{query} for method #{@req.method} with the headers #{@req.options[:head].inspect} isn't registered, and pass_through_requests is current set to false"
      end
    end
  end
end
