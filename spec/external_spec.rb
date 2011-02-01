require 'helper'

requires_connection do

  describe EventMachine::HttpRequest do

    it "should follow redirects on HEAD method (external)", :online do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.google.com/').head :redirects => 1
        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          EM.stop
        }
      }
    end

    it "should perform a streaming GET" do
      EventMachine.run {

        # digg.com uses chunked encoding
        http = EventMachine::HttpRequest.new('http://digg.com/news').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          EventMachine.stop
        }
      }
    end

    context "keepalive", :online => true do
      it "should default to non-keepalive" do
        EventMachine.run {
          headers = {'If-Modified-Since' => 'Thu, 05 Aug 2010 22:54:44 GMT'}
          http = EventMachine::HttpRequest.new('http://www.google.com/images/logos/ps_logo2.png').get :head => headers

          http.errback { fail }
          start = Time.now.to_i
          http.callback {
            (start - Time.now.to_i).should be_within(1).of(0)
            EventMachine.stop
          }
        }
      end

      it "should work with keep-alive servers" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://mexicodiario.com/touch.public.json.php').get :keepalive => true

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            EventMachine.stop
          }
        }
      end
    end

  end
end
