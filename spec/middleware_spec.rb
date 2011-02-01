require 'helper'

describe EventMachine::HttpRequest do

  class TestMiddleware
    def self.request
    end

    def self.response(resp)
      resp.response_header['X-Header'] = 'middleware'
      resp.response = 'Hello, Middleware!'
    end
  end

  module EmptyMiddleware; end

  class GlobalMiddleware
    def self.response(resp)
      resp.response_header['X-Global'] = 'middleware'
    end
  end

  it "should accept middleware" do
    EventMachine.run {
      lambda {
        conn = EM::HttpRequest.new('http://127.0.0.1:8090') 
        conn.use TestMiddleware
        conn.use EmptyMiddleware

        EM.stop
      }.should_not raise_error
    }
  end

  it "should execute response middleware before user callbacks" do
   EventMachine.run {
      conn = EM::HttpRequest.new('http://127.0.0.1:8090') 
      conn.use TestMiddleware

      req = conn.get
      req.callback {
        req.response_header['X-Header'].should match('middleware')
        req.response.should match('Hello, Middleware!')
        EM.stop
      }
    }
  end

  it "should execute global response middleware before user callbacks" do
   EventMachine.run {
      EM::HttpRequest.use GlobalMiddleware

      conn = EM::HttpRequest.new('http://127.0.0.1:8090')

      req = conn.get
      req.callback {
        req.response_header['X-Global'].should match('middleware')
        EM.stop
      }
    }
  end

end
