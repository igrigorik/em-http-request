require 'helper'

describe EventMachine::HttpRequest do
  def failed(http=nil)
    EventMachine.stop
    http ? fail(http.error) : fail
  end

  it "should respond to then" do
    EventMachine.run {
      EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get.should respond_to(:then)
      EventMachine.stop
    }
  end

  it "should call the success callback with a block" do
    stub = double("stub")
    stub.stub(:called_back)
    stub.should_receive(:called_back)
    EventMachine.run {
      EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get.then { |response|
        response.response_header.status.should == 200
        stub.called_back
        EventMachine.stop
      }
    }
  end

  it "should call the success callback with a lambda" do
    stub = double("stub")
    stub.stub(:called_back)
    stub.should_receive(:called_back)
    EventMachine.run {
      EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get.then(
        ->(response) {
          response.response_header.status.should == 200
          stub.called_back
          EventMachine.stop
        }
      )
    }
  end

  it "should pass the promise to the next promise handler" do
    stub = double("stub")
    stub.stub(:called_back)
    stub.should_receive(:called_back).twice
    EventMachine.run {
      EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get.then(
        ->(response) {
          response.response_header.status.should == 200
          stub.called_back
          EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get
        }
      ).then(
        ->(response) {
          response.response_header.status.should == 200
          stub.called_back
          EventMachine.stop
        }
      )
    }    
  end

  it "should pass failures through to the final error handler" do
    stub = double("stub")
    stub.stub(:called_back)
    stub.should_receive(:called_back)
    EventMachine.run {
      EventMachine::HttpRequest.new('http://127.0.0.1:8090/fail').get.then {
        EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get
      }.then(
        ->(response) {
          EventMachine.stop
        },
        ->(response) {
          stub.called_back
          EventMachine.stop
        }
      )
    }    
  end

end