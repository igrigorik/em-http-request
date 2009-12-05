require 'base64'
require 'addressable/uri'

module EventMachine

  # EventMachine based HTTP request class with support for streaming consumption
  # of the response. Response is parsed with a Ragel-generated whitelist parser
  # which supports chunked HTTP encoding.
  #
  # == Example
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
    
    attr_reader :options, :method

    def initialize(host, headers = {})
      @headers = headers
      @uri = host.kind_of?(Addressable::URI) ? host : Addressable::URI::parse(host)
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
    #   on_response: Proc
    #     Called for each response body chunk (you may assume HTTP 200
    #     OK then)
    #
                                   
    def get    options = {};  setup_request(:get,  options);    end
    def head   options = {};  setup_request(:head, options);    end
    def delete options = {};  setup_request(:delete, options);  end
    def put    options = {};  setup_request(:put, options);     end
    def post   options = {};  setup_request(:post, options);    end

    protected

    def setup_request(method, options)
      raise ArgumentError, "invalid request path" unless /^\// === @uri.path
      @options = options
      
      if proxy = options[:proxy]
        @host_to_connect = proxy[:host]
        @port_to_connect = proxy[:port]
      else
        @host_to_connect = @uri.host
        @port_to_connect = @uri.port
      end                                      
      
      # default connect & inactivity timeouts        
      @options[:timeout] = 10 if not @options[:timeout]  

      # Make sure the ports are set as Addressable::URI doesn't
      # set the port if it isn't there
      @uri.port ||= 80
      @port_to_connect ||= 80
      
      @method = method.to_s.upcase
      send_request
    end
    
    def send_request
      begin
       EventMachine.connect(@host_to_connect, @port_to_connect, EventMachine::HttpClient) { |c|
          c.uri = @uri
          c.method = @method
          c.options = @options
          c.comm_inactivity_timeout = @options[:timeout]
          c.pending_connect_timeout = @options[:timeout]
        }
      rescue EventMachine::ConnectionError => e
        conn = EventMachine::HttpClient.new("")
        conn.on_error(e.message, true)
        conn
      end
    end
  end
end