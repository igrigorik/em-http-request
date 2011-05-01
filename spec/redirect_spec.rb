require 'helper'

class RedirectMiddleware
  attr_reader :call_count

  def initialize
    @call_count = 0
  end

  def request(c, h, r)
    @call_count += 1
    [h.merge({'EM-Middleware' => @call_count.to_s}), r]
  end
end

class PickyRedirectMiddleware < RedirectMiddleware
  def response(r)
    if r.redirect? && r.response_header['LOCATION'][-1] == '3'
      # set redirects to 0 to avoid further processing
      r.req.redirects = 0
    end
  end
end

describe EventMachine::HttpRequest do

  it "should follow location redirects" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect').get :redirects => 1
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
        http.redirects.should == 1

        EM.stop
      }
    }
  end

  it "should redirect with missing content-length" do
    EventMachine.run {
      @s = StubServer.new("HTTP/1.0 301 MOVED PERMANENTLY\r\nlocation: http://127.0.0.1:8090/redirect\r\n\r\n")

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get :redirects => 3
      http.errback { failed(http) }

      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
        http.redirects.should == 3

        @s.stop
        EM.stop
      }
    }
  end

  it "should follow redirects on HEAD method" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/head').head :redirects => 1
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/'
        EM.stop
      }
    }
  end

  it "should report last_effective_url" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/'

        EM.stop
      }
    }
  end

  it "should default to 0 redirects" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect').get
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 301
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/redirect'
        http.redirects.should == 0

        EM.stop
      }
    }
  end

  it "should not invoke redirect logic on failed(http) connections" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/', :connect_timeout => 0.1).get :redirects => 5
      http.callback { failed(http) }
      http.errback {
        http.redirects.should == 0
        EM.stop
      }
    }
  end

  it "should normalize redirect urls" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/bad').get :redirects => 1
      http.errback { failed(http) }
      http.callback {
        http.last_effective_url.to_s.should match('http://127.0.0.1:8090/')
        http.response.should match('Hello, World!')
        EM.stop
      }
    }
  end

  it "should fail gracefully on a missing host in absolute Location header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/nohost').get :redirects => 1
      http.callback { failed(http) }
      http.errback {
        http.error.should == 'Location header format error'
        EM.stop
      }
    }
  end

  it "should capture and pass cookies on redirect and pass_cookies by default" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/multiple-with-cookie').get :redirects => 2, :head => {'cookie' => 'id=2;'}
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
        http.redirects.should == 2
        http.cookies.should include("id=2;")
        http.cookies.should include("another_id=1; expires=Tue, 09-Aug-2011 17:53:39 GMT; path=/;")

        EM.stop
      }
    }
  end

  it "should capture and not pass cookies on redirect if passing is disabled via pass_cookies" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/multiple-with-cookie').get :redirects => 2, :pass_cookies => false, :head => {'cookie' => 'id=2;'}
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
        http.redirects.should == 2
        http.cookies.should include("id=2;")
        http.cookies.should_not include("another_id=1; expires=Tue, 09-Aug-2011 17:53:39 GMT; path=/;")

        EM.stop
      }
    }
  end

  it "should call middleware each time it redirects" do
    EventMachine.run {
      conn = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/middleware_redirects_1')
      conn.use RedirectMiddleware
      http = conn.get :redirects => 3
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header['EM_MIDDLEWARE'].to_i.should == 3
        EM.stop
      }
    }
  end

  it "should call middleware which may reject a redirection" do
    EventMachine.run {
      conn = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/middleware_redirects_1')
      conn.use PickyRedirectMiddleware
      http = conn.get :redirects => 3
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 301
        http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/redirect/middleware_redirects_2'
        EM.stop
      }
    }
  end

end
