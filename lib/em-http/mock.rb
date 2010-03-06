module EventMachine
  class MockHttpRequest < EventMachine::HttpRequest
    
    include HttpEncoding
    
    class FakeHttpClient < EventMachine::HttpClient

      def setup(response, uri)
        @uri = uri
        receive_data(response)
        succeed(self) 
      end
      
      def unbind
      end
      
    end
    
    @@registry = nil
    @@registry_count = nil
    
    def self.reset_counts!
      @@registry_count = Hash.new do |registry,query| 
        registry[query] = Hash.new{|h,k| h[k] = Hash.new(0)}
      end
    end
    
    def self.reset_registry!
      @@registry = Hash.new do |registry,query| 
        registry[query] = Hash.new{|h,k| h[k] = {}}
      end
    end
    
    reset_counts!
    reset_registry!
    
    @@pass_through_requests = true

    def self.pass_through_requests=(pass_through_requests)
      @@pass_through_requests = pass_through_requests
    end
    
    def self.pass_through_requests
      @@pass_through_requests
    end
    
    def self.register(uri, method, headers, data)
      method = method.to_s.upcase
      headers = headers.to_s
      @@registry[uri][method][headers] = data
    end
    
    def self.register_file(uri, method, headers, file)
      register(uri, method, headers, File.read(file))
    end
    
    def self.count(uri, method, headers)
      method = method.to_s.upcase
      headers = headers.to_s
      @@registry_count[uri][method][headers] rescue 0
    end
    
    def self.registered?(query, method, headers)
      @@registry[query] and @@registry[query][method] and @@registry[query][method][headers]
    end
    
    def self.registered_content(query, method, headers)
      @@registry[query][method][headers]
    end
    
    def self.increment_access(query, method, headers)
      @@registry_count[query][method][headers] += 1
    end
    
    alias_method :real_send_request, :send_request
    
    protected
    def send_request(&blk)
      query = "#{@uri.scheme}://#{@uri.host}:#{@uri.port}#{encode_query(@uri.path, @options[:query], @uri.query)}"
      headers = @options[:head].to_s
      if self.class.registered?(query, @method, headers)
        self.class.increment_access(query, @method, headers)
        client = FakeHttpClient.new(nil)
        client.setup(self.class.registered_content(query, @method, headers), @uri)
        client
      elsif @@pass_through_requests
        real_send_request
      else
        raise "this request #{query} for method #{@method} with the headers #{@options[:head].inspect} isn't registered, and pass_through_requests is current set to false"
      end
    end
  end
end
