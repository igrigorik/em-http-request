require 'helper'

describe EventMachine::HttpRequest do

  context "connections via" do
    let(:proxy) { {:proxy => { :host => '127.0.0.1', :port => 8083 }} }
    let(:authenticated_proxy) { {:proxy => { :host => '127.0.0.1', :port => 8083, :authorization => ["user", "name"] } } }

    it "should use HTTP proxy" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test', proxy).get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response_header.should_not include("X_PROXY_AUTH")
          http.response.should match('test')
          EventMachine.stop
        }
      }
    end

    it "should use HTTP proxy with authentication" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/proxyauth?q=test', authenticated_proxy).get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response_header['X_PROXY_AUTH'].should == "Proxy-Authorization: Basic dXNlcjpuYW1l"
          http.response.should match('test')
          EventMachine.stop
        }
      }
    end

    it "should send absolute URIs to the proxy server" do
      EventMachine.run {

        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test', proxy).get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200

          # The test proxy server gives the requested uri back in this header
          http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/?q=test'
          http.response_header['X_THE_REQUESTED_URI'].should_not == '/?q=test'
          http.response.should match('test')
          EventMachine.stop
        }
      }
    end

    it "should strip basic auth from before the host in URI sent to proxy" do
      EventMachine.run {

        http = EventMachine::HttpRequest.new('http://user:pass@127.0.0.1:8090/echo_authorization_header', proxy).get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          # The test proxy server gives the requested uri back in this header
          http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/echo_authorization_header'
          # Ensure the basic auth was converted to a header correctly
          http.response.should match('authorization:Basic dXNlcjpwYXNz')
          EventMachine.stop
        }
      }
    end

    it "should include query parameters specified in the options" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/', proxy).get :query => { 'q' => 'test' }

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should match('test')
          EventMachine.stop
        }
      }
    end

    it "should use HTTP proxy while redirecting" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect', proxy).get :redirects => 1

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200

          http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/gzip'
          http.response_header['X_THE_REQUESTED_URI'].should_not == '/redirect'

          http.response_header["CONTENT_ENCODING"].should == "gzip"
          http.response.should == "compressed"
          http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
          http.redirects.should == 1

          EventMachine.stop
        }
      }
    end
  end

end
