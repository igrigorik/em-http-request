require 'helper'

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

  # it "should redirect with missing content-length" do
  #   EventMachine.run {
  #     @s = StubServer.new("HTTP/1.0 301 MOVED PERMANENTLY\r\nlocation: http://127.0.0.1:8090/redirect\r\n\r\n")
  #
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get :redirects => 3
  #     http.errback { p http; failed(http) }
  #
  #     http.callback {
  #       http.response_header.status.should == 200
  #       http.response_header["CONTENT_ENCODING"].should == "gzip"
  #       http.response.should == "compressed"
  #       http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
  #       http.redirects.should == 2
  #
  #       @s.stop
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should follow redirects on HEAD method" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/head').head :redirects => 1
  #     http.errback { failed(http) }
  #     http.callback {
  #       http.response_header.status.should == 200
  #       http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/'
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should report last_effective_url" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get
  #     http.errback { failed(http) }
  #     http.callback {
  #       http.response_header.status.should == 200
  #       http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/'
  #
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should default to 0 redirects" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect').get
  #     http.errback { failed(http) }
  #     http.callback {
  #       http.response_header.status.should == 301
  #       http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
  #       http.redirects.should == 0
  #
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should not invoke redirect logic on failed(http) connections" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get :timeout => 0.1, :redirects => 5
  #     http.callback { failed(http) }
  #     http.errback {
  #       http.redirects.should == 0
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should normalize redirect urls" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/bad').get :redirects => 1
  #     http.errback { failed(http) }
  #     http.callback {
  #       http.last_effective_url.to_s.should match('http://127.0.0.1:8090/')
  #       http.response.should match('Hello, World!')
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should fail gracefully on a missing host in absolute Location header" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/nohost').get :redirects => 1
  #     http.callback { failed(http) }
  #     http.errback {
  #       http.error.should == 'Location header format error'
  #       EM.stop
  #     }
  #   }
  # end
  #
  # it "should reset host on redirect" do
  #   EventMachine.run {
  #     http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect').get :redirects => 1, :host => '127.0.0.1'
  #
  #     http.errback { failed(http) }
  #     http.callback {
  #       http.response_header.status.should == 200
  #       http.response_header["CONTENT_ENCODING"].should == "gzip"
  #       http.response.should == "compressed"
  #       http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
  #       http.redirects.should == 1
  #
  #       EM.stop
  #     }
  #   }
  # end

end