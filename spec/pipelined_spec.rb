require 'helper'

describe EventMachine::HttpRequest do

  it "should perform successful GET" do
    EventMachine.run do
      conn = EventMachine::HttpRequest.connect('http://www.igvita.com/')
      pipe1 = conn.get :keepalive => true
      pipe2 = conn.get :keepalive => true

      processed = 0
      stop = proc { EM.stop if processed == 2}

      pipe1.errback { failed(http) }
      pipe1.callback {
        processed += 1
        pipe1.response_header.status.should == 200
        stop.call
      }

      pipe2.errback { failed(http) }
      pipe2.callback {
        processed += 1
        pipe2.response_header.status.should == 200
        stop.call
      }

    end
  end
end
