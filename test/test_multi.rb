require 'test/helper'
require 'test/stallion'

describe EventMachine::MultiRequest do

  def failed
    EventMachine.stop
    fail
  end

  it "should submit multiple requests in parallel and return once all of them are complete" do
    EventMachine.run {
      
      # create an instance of multi-request handler, and the requests themselves
      multi = EventMachine::MultiRequest.new
      
      # add multiple requests to the multi-handler
      multi.add(EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get(:query => {:q => 'test'}))
      multi.add(EventMachine::HttpRequest.new('http://169.169.169.169/').get)
      
      multi.callback  {
        # verify successfull request
        multi.responses[:succeeded].size.should == 1
        multi.responses[:succeeded].first.response.should match(/test/)
        
        # verify invalid requests
        multi.responses[:failed].size.should == 1
        multi.responses[:failed].first.response_header.status.should == 0
        
        EventMachine.stop
      }
    } 
  end
end