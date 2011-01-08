require 'helper'

describe EventMachine::HttpRequest do

  context "connections via" do
    context "direct proxy" do
      it "should default to skip CONNECT" do
        EventMachine.run {

          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test').get :proxy => {
            :host => '127.0.0.1', :port => 8083
          }

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

          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test').get :proxy => {
            :host => '127.0.0.1', :port => 8083
          }

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

          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get(
            :proxy => { :host => '127.0.0.1', :port => 8083 },
            :query => { 'q' => 'test' }
          )

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

  context "CONNECT proxy" do
    it "should work with CONNECT proxy servers" do
      EventMachine.run {
        opts = {:proxy => {:host => '127.0.0.1', :port => 8082, :use_connect => true}}
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get(opts)

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should == 'Hello, World!'
          EventMachine.stop
        }
      }
    end
  end

  it "should proxy POST data" do
    EventMachine.run {
      opts = {:body => "data", :proxy => {:host => '127.0.0.1', :port => 8082, :use_connect => true}}
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post(opts)

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/data/)
        EventMachine.stop
      }
    }
  end
end