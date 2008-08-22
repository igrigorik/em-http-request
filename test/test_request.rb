require 'test/helper'

# TODO: rewrite tests against a temporary web-server

describe EventMachine::HttpRequest do

  it "should fail GET on invalid host" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://192.168.0.110/').get 
      
      http.errback {
	http.response_header.status.should == 0
	EventMachine.stop
      }
    }
  end

  it "should fail GET on missing path" do 
    EventMachine.run {
      lambda {
	EventMachine::HttpRequest.new('http://192.168.0.110').get 
      }.should raise_error(ArgumentError)
      
      EventMachine.stop
    }
  end
  
  it "should perform successfull GET" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1/').get 
      
      http.callback {
	http.response_header.status == 200
	EventMachine.stop
      }
    }
  end

  it "should perform successfull GET with custom path and query string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1/path').get :query => {:keyname => 'value'} 
      
      http.callback {
	http.response_header.status == 200
	EventMachine.stop
      }
    }
  end
  
  it "should perform successfull POST" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1/').post :body => "HAI"
   
      http.callback { 
	p "SUCCESS"
        p http.response
	EventMachine.stop
      }
    }
  end

  it "should perform successfull GET with custom header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1/path').get :head => {'If-Modified-Since' => 'evar!'}
      
      http.callback {
	http.response_header.status == 200
	EventMachine.stop
      }
    }
  end
  
end