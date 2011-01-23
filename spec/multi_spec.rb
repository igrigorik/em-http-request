require 'helper'
require 'stallion'

describe EventMachine::MultiRequest do

  it "should submit multiple requests in parallel and return once all of them are complete" do
    EventMachine.run {

      # create an instance of multi-request handler, and the requests themselves
      multi = EventMachine::MultiRequest.new

      # add multiple requests to the multi-handler
      multi.add(EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get(:query => {:q => 'test'}))
      multi.add(EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get)

      multi.callback  {
        multi.responses[:succeeded].size.should == 2
        multi.responses[:succeeded][0].response.should match(/test|Hello/)
        multi.responses[:succeeded][1].response.should match(/test|Hello/)

        EventMachine.stop
      }
    }
  end

  it "should accept multiple open connections and return once all of them are complete" do
    EventMachine.run {
      http1 = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get(:query => {:q => 'test'})
      http2 = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get

      multi = EventMachine::MultiRequest.new([http1, http2]) do
        multi.responses[:succeeded].size.should == 2
        multi.responses[:succeeded][0].response.should match(/test|Hello/)
        multi.responses[:succeeded][1].response.should match(/test|Hello/)

        EventMachine.stop
      end
    }
  end

end