require 'test/helper'
 
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
      http = EventMachine::HttpRequest.new('http://google.com/').get
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 301 
	EventMachine.stop
      }
    }
  end
   
  it "should return 404 on invalid path" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.com/path').get :query => {:keyname => 'value'}
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 404
	EventMachine.stop
      }
    }
  end

  it "should perform valid search" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.com/search').get :query => {:q => 'test'}
      
      http.errback { failed }
      http.callback {
	http.response_header.status.should == 200
	http.response.should match(/test/)
	EventMachine.stop
      }
    }
  end

  # google has post disabled  
  it "should perform successfull POST" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.com/search').post :body => "q=test"
   
      http.errback { failed }
      http.callback {
	http.response_header.status == 501
	EventMachine.stop
      }
    }
  end

  # need a better endpoint
  it "should perform successfull GET with custom header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.com/').get :head => {'If-Modified-Since' => 'evar!'}
   
      http.errback { failed }
      http.callback {
	http.response_header.status == 200
	EventMachine.stop
      }
    }
  end
  
  # need a better endpoint  
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