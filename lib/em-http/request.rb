require 'uri'

module EventMachine

  # EventMachine based HTTP request class with support for streaming consumption
  # of the response. Response is parsed with a Ragel-generated whitelist parser
  # which supports chunked HTTP encoding.
  # 
  # == Example
  # 
  # 
  #  EventMachine.run {
  #    http = EventMachine::HttpRequest.new('http://127.0.0.1/').get :query => {'keyname' => 'value'}
  # 
  #    http.callback {
  #     p http.response_header.status
  #     p http.response_header
  #     p http.response
  # 
  #	EventMachine.stop
  #    }
  #  }
  # 
  
  class HttpRequest
    attr_reader :response, :headers
    
    def initialize(host, headers = {})
      @headers = headers
      @uri = URI::parse(host)
    end
   
    # Send an HTTP request and consume the response. Supported options:
    # 
    #   head: {Key: Value}
    #     Specify an HTTP header, e.g. {'Connection': 'close'}
    # 
    #   query: {Key: Value}
    #     Specify query string parameters (auto-escaped)
    # 
    #   body: String
    #     Specify the request body (you must encode it for now)
    #
    
    def get  options = {};    send_request(:get,  options);    end
    def post options = {};    send_request(:post, options);    end

    protected
    
    def send_request(method, options)
      raise ArgumentError, "invalid request path" unless /^\// === @uri.path
   
      method = method.to_s.upcase

      EventMachine.connect(@uri.host, @uri.port, EventMachine::HttpClient) { |c|
        c.uri = @uri
        c.method = method
        c.options = options
      }
    end
  end
end