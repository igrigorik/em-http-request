require 'helper'

describe EventMachine::HttpRequest do

  xit "should fail gracefully on an invalid host in Location header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect/badhost').get :redirects => 1
      http.callback { failed(http) }
      http.errback {
        http.error.should == 'unable to resolve server address'
        EM.stop
      }
    }
  end

  xit "should fail GET on DNS timeout" do
    EventMachine.run {
      EventMachine.heartbeat_interval = 0.1
      http = EventMachine::HttpRequest.new('http://127.1.1.1/').get :timeout => 1
      http.callback { failed(http) }
      http.errback {
        http.response_header.status.should == 0
        EventMachine.stop
      }
    }
  end

  xit "should fail GET on invalid host" do
    EventMachine.run {
      EventMachine.heartbeat_interval = 0.1
      http = EventMachine::HttpRequest.new('http://somethinglocal/').get :timeout => 1
      http.callback { failed(http) }
      http.errback {
        http.response_header.status.should == 0
        http.error.should match(/unable to resolve server address/)
        http.uri.to_s.should match('http://somethinglocal:80/')
        EventMachine.stop
      }
    }
  end

end