require 'helper'
require 'stallion'

describe EventMachine::MultiRequest do

  it "should submit multiple requests in parallel and return once all of them are complete" do
    EventMachine.run {

      # create an instance of multi-request handler, and the requests themselves
      multi = EventMachine::MultiRequest.new

      # add multiple requests to the multi-handler
      multi.add(EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get(:query => {:q => 'test'}))
      multi.add(EventMachine::HttpRequest.new('http://0.0.0.0:8083/').get(:timeout => 1))

      multi.callback  {
        # verify successful request
        multi.responses[:succeeded].size.should == 1
        multi.responses[:succeeded].first.response.should match(/test/)

        # verify invalid requests
        multi.responses[:failed].size.should == 1
        multi.responses[:failed].first.response_header.status.should == 0

        EventMachine.stop
      }
    }
  end

  it "should accept multiple open connections and return once all of them are complete" do
    EventMachine.run {
      http1 = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get(:query => {:q => 'test'})
      http2 = EventMachine::HttpRequest.new('http://0.0.0.0:8083/').get(:timeout => 1)

      multi = EventMachine::MultiRequest.new([http1, http2]) do
        multi.responses[:succeeded].size.should == 1
        multi.responses[:succeeded].first.response.should match(/test/)

        multi.responses[:failed].size.should == 1
        multi.responses[:failed].first.response_header.status.should == 0

        EventMachine.stop
      end
    }
  end

  it "should handle multiple mock requests" do
    EventMachine::MockHttpRequest.register_file('http://127.0.0.1:8080/', :get, {}, File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'))
    EventMachine::MockHttpRequest.register_file('http://0.0.0.0:8083/', :get, {}, File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'))

    EventMachine.run {

      # create an instance of multi-request handler, and the requests themselves
      multi = EventMachine::MultiRequest.new

      # add multiple requests to the multi-handler
      multi.add(EventMachine::MockHttpRequest.new('http://127.0.0.1:8080/').get)
      multi.add(EventMachine::MockHttpRequest.new('http://0.0.0.0:8083/').get)

      multi.callback  {
        # verify successful request
        multi.responses[:succeeded].size.should == 2

        EventMachine.stop
      }
    }
  end
end
