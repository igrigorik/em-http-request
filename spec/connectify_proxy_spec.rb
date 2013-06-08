require 'helper'

requires_connection do
  requires_port(3128) do
    describe EventMachine::HttpRequest do

      let(:proxy) { {:proxy => { :host => '127.0.0.1', :port => 3128, :type => :connect }} }

      it "should use CONNECT proxy" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://jsonip.com/', proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response.should match('173.230.151.99')
            EventMachine.stop
          }
        }
      end
    end
  end
end
