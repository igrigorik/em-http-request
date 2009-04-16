require 'test/helper'
require 'test/stallion'

describe EventMachine::HttpRequest do

  def failed
    EventMachine.stop
    fail
  end

  it "should fail GET on DNS timeout" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.1.1.1/').get
      http.callback { failed }
      http.errback {
        http.response_header.status.should == 0
        EventMachine.stop
      }
    }
  end

 it "should fail GET on invalid host" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://google1.com/').get
      http.callback { failed }
      http.errback {
        http.response_header.status.should == 0
        http.errors.should match(/no connection/)
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

  it "should build query parameters from Hash" do
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

  it "should pass query parameters string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :query => "q=test"

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/test/)
        EventMachine.stop
      }
    }
  end

  it "should encode an array of query parameters" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/echo_query').get :query => {:hash => ['value1', 'value2']}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/hash\[\]=value1&hash\[\]=value2/)
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

  it "should perform a streaming GET" do
    EventMachine.run {

      # digg.com uses chunked encoding
      http = EventMachine::HttpRequest.new('http://digg.com/').get

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should perform basic auth" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :head => {'authorization' => ['user', 'pass']}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should work with keep-alive servers" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://mexicodiario.com/touch.public.json.php').get

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should detect deflate encoding" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/deflate').get :head => {"accept-encoding" => "deflate"}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "deflate"
        http.response.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should detect gzip encoding" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/gzip').get :head => {"accept-encoding" => "gzip, compressed"}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should timeout after 10 seconds" do
    EventMachine.run {
      t = Time.now.to_i
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/timeout').get :timeout => 2

      http.errback {
        (Time.now.to_i - t).should == 2
        EventMachine.stop
      }
      http.callback { failed }
    }
  end

  it "should optionally pass the response body progressively" do
    EventMachine.run {
      body = ''
      on_body = lambda { |chunk| body += chunk }
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :on_response => on_body

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == ''
        body.should match(/Hello/)
        EventMachine.stop
      }
    }
  end
end
