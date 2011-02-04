require 'helper'

requires_connection do

  describe EventMachine::HttpRequest do

    it "should initiate SSL/TLS on HTTPS connections" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail/').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 302
          EventMachine.stop
        }
      }
    end
  end

end
