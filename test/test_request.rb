require 'test/helper'
require 'test/stallion'

describe EventMachine::HttpRequest do

  def failed
    EventMachine.stop
    fail
  end

  it "should fail GET on invalid host" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://169.169.169.169/').get
      http.callback { failed }
      http.errback {
	http.response_header.status.should == 0
	EventMachine.stop
      }
    }
  end
   
  it "should fail GET on missing path" do
    EventMachine.run {
      lambda {
	EventMachine::HttpRequest.new('http://www.google.com').get
      }.should raise_error(ArgumentError)
   
      EventMachine.stop
    }
  end
   
  it "should perform successfull GET" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 200 
	http.response.should match(/Hello/)
	EventMachine.stop
      }
    }
  end
   
  it "should return 404 on invalid path" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/fail').get
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 404
	EventMachine.stop
      }
    }
  end

  it "should pass query parameters" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :query => {:q => 'test'}
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 200
	http.response.should match(/test/)
	EventMachine.stop
      }
    }
  end

  it "should perform successfull POST" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').post :body => "data"
   
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 200
	http.response.should match(/test/)
	EventMachine.stop
      }
    }
  end

  it "should perform successfull GET with custom header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :head => {'if-none-match' => 'evar!'}
   
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 304
	EventMachine.stop
      }
    }
  end
  
  # need an actual streaming endpoint  
  it "should perform a streaming GET" do
    EventMachine.run {
   
      http = EventMachine::HttpRequest.new('http://www.google.com/').get
   
      http.errback { failed }
      http.callback {
	http.response_header.status == 200
	EventMachine.stop
      }
    }
  end
  
end