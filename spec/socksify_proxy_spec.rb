require 'helper'

requires_connection do
  requires_port(8080) do
    describe EventMachine::HttpRequest do

      # ssh -D 8080 igvita
      let(:proxy) { {:proxy => { :host => '127.0.0.1', :port => 8080, :type => :socks5 }} }

      it "should use SOCKS5 proxy" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://jsonip.com/', proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response.should match('72.52.131')
            EventMachine.stop
          }
        }
      end
    end
  end
end
