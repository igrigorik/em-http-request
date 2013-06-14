require 'helper'

requires_connection do
  requires_port(3128) do
    describe EventMachine::HttpRequest do

      let(:http_proxy) { {:proxy => { :host => '127.0.0.1', :port => 3128, :type => :http }} }
      let(:default_proxy) { {:proxy => { :host => '127.0.0.1', :port => 3128 }} }

      it "should use CONNECT proxy for HTTPS requests when :http specified" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('https://ipjson.herokuapp.com/', http_proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response.should match('173.230.151.99')
            EventMachine.stop
          }
        }
      end

      it "should use CONNECT proxy for HTTPS when no type specified" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('https://ipjson.herokuapp.com/', default_proxy).get

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
