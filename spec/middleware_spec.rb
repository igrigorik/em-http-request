require 'helper'

describe EventMachine::HttpRequest do

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
        conn.use ResponseMiddleware
        conn.use EmptyMiddleware

        EM.stop
      }.should_not raise_error
    }
  end

  context "request" do
    class ResponseMiddleware
      def self.response(resp)
        resp.response_header['X-Header'] = 'middleware'
        resp.response = 'Hello, Middleware!'
      end
    end


    it "should execute response middleware before user callbacks" do
      EventMachine.run {
        conn = EM::HttpRequest.new('http://127.0.0.1:8090')
        conn.use ResponseMiddleware

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

  context "request" do
    class RequestMiddleware
      def self.request(head, body)
        head['X-Middleware'] = 'middleware'   # insert new header
        body += ' modified'                   # modify post body

        [head, body]
      end
    end

    it "should execute request middleware before dispatching request" do
      EventMachine.run {
        conn = EventMachine::HttpRequest.new('http://127.0.0.1:8090/')
        conn.use RequestMiddleware

        req = conn.post :body => "data"
        req.callback {
          req.response_header.status.should == 200
          req.response.should match(/data modified/)
          EventMachine.stop
        }
      }
    end
  end

  context "jsonify" do
    class JSONify
      require 'json'

      def self.request(head, body)
        [head, JSON.generate(body)]
      end

      def self.response(resp)
        resp.response = JSON.parse(resp.response)
      end
    end

    it "should use middleware to JSON encode and JSON decode the body" do
      EventMachine.run {
        conn = EventMachine::HttpRequest.new('http://127.0.0.1:8090/')
        conn.use JSONify

        req = conn.post :body => {:ruby => :hash}
        req.callback {
          req.response_header.status.should == 200
          req.response.should == {"ruby" => "hash"}
          EventMachine.stop
        }
      }
    end
  end

end
