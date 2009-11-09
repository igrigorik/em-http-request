module EventMachine
  class HttpRequest
    
    class FakeHttpClient < EventMachine::HttpClient

      def setup(response)
        receive_data(response)
        succeed(self) 
      end
      
    end
    
    @@registry = Hash.new{|h,k| h[k] = {}}
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
    
    alias_method :real_send_request, :send_request
    
    protected
    def send_request
      if s = @@registry[@uri.to_s] and fake = s[@method]
        client = FakeHttpClient.new
        client.setup(fake)
        client
      elsif @@pass_through_requests
        real_send_request @method, @options
      else
        raise "this request #{@uri.to_s} #{@method} isn't registered, and pass_through_requests is current set to false"
      end
    end
  end
end
