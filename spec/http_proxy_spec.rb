require 'helper'

describe EventMachine::HttpRequest do

  context "connections via" do
    let(:proxy) { {:proxy => { :host => '127.0.0.1', :port => 8083 }} }

    it "should use HTTP proxy" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test', proxy).get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
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
  end

end