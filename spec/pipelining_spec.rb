require 'helper'

requires_connection do

  describe EventMachine::HttpRequest do

    it "should perform successful pipelined GETs" do
      EventMachine.run do

        # Mongrel doesn't support pipelined requests - bah!
        conn = EventMachine::HttpRequest.new('http://www.igvita.com/')

        pipe1 = conn.get :keepalive => true
        pipe2 = conn.get :path => '/about/', :keepalive => true

        processed = 0
        stop = proc { EM.stop if processed == 2}

        pipe1.errback { failed(conn) }
        pipe1.callback {
          processed += 1
          pipe1.response_header.status.should == 200
          stop.call
        }

        pipe2.errback { p pipe2; failed(conn) }
        pipe2.callback {
          processed += 1
          pipe2.response_header.status.should == 200
          pipe2.response.should match(/ilya/i)
          stop.call
        }

      end
    end
  end

end
