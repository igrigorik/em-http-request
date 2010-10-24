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
  #  EventMachine.stop
  #    }
  #  }
  #

  class HttpRequest

    attr_reader :options, :method

    def initialize(host)
      @uri = host.kind_of?(Addressable::URI) ? host : Addressable::URI::parse(host.to_s)
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

    def get    options = {}, &blk;  setup_request(:get,   options, &blk);   end
    def head   options = {}, &blk;  setup_request(:head,  options, &blk);   end
    def delete options = {}, &blk;  setup_request(:delete,options, &blk);   end
    def put    options = {}, &blk;  setup_request(:put,   options, &blk);   end
    def post   options = {}, &blk;  setup_request(:post,  options, &blk);   end

    protected

    def setup_request(method, options, &blk)
      @req = HttpOptions.new(method, @uri, options)
      send_request(&blk)
    end

    def send_request(&blk)
      begin
        EventMachine.connect(@req.host, @req.port, EventMachine::HttpClient) { |c|
          c.uri = @req.uri
          c.method = @req.method
          c.options = @req.options
          c.comm_inactivity_timeout = @req.options[:timeout]
          c.pending_connect_timeout = @req.options[:timeout]
          blk.call(c) unless blk.nil?
        }
      rescue EventMachine::ConnectionError => e
        conn = EventMachine::HttpClient.new("")
        conn.on_error(e.message, true)
        conn.uri = @req.uri
        conn
      end
    end
  end
end