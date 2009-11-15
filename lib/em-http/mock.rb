module EventMachine
  class HttpRequest
    
    class FakeHttpClient < EventMachine::HttpClient

      def setup(response)
        receive_data(response)
        succeed(self) 
      end
      
      def unbind
        succeed(self) 
      end
      
    end
    
    @@registry = Hash.new{|h,k| h[k] = {}}
    @@registry_count = nil
    
    def self.reset_counts!
      @@registry_count = Hash.new{|h,k| h[k] = Hash.new(0)}
    end
    
    reset_counts!
    
    @@pass_through_requests = true

    def self.pass_through_requests=(pass_through_requests)
      @@pass_through_requests = pass_through_requests
    end
    
    def self.pass_through_requests
      @@pass_through_requests
    end
    
    def self.register(uri, method, data)
      method = method.to_s.upcase
      @@registry[uri][method] = data
    end
    
    def self.register_file(uri, method, file)
      register(uri, method, File.read(file))
    end
    
    def self.count(uri, method)
      method = method.to_s.upcase
      @@registry_count[uri][method]
    end
    
    alias_method :real_send_request, :send_request
    
    protected
    def send_request
      query = "#{@uri.scheme}://#{@uri.host}:#{@uri.port}#{HttpEncoding.encode_query(@uri.path, @options[:query], @uri.query)}"
      if s = @@registry[query] and fake = s[@method]
        @@registry_count[query][@method] += 1
        client = FakeHttpClient.new(nil)
        client.setup(fake)
        client
      elsif @@pass_through_requests
        real_send_request
      else
        raise "this request #{query} for method #{@method} isn't registered, and pass_through_requests is current set to false"
      end
    end
  end
end
