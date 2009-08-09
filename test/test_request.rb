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
  
  it "should perform successfull GET with a URI passed as argument" do
    EventMachine.run {
      uri = URI.parse('http://127.0.0.1:8080/')
      http = EventMachine::HttpRequest.new(uri).get

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
        http.response.should match(/data/)
        EventMachine.stop
      }
    }
  end

  it "should perform successfull POST with Ruby Hash/Array as params" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').post :body => {"key1" => 1, "key2" => [2,3]}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        
        http.response.should match(/key1=1&key2\[0\]=2&key2\[1\]=3/)
        EventMachine.stop
      }
    }
  end
  
  it "should perform successfull POST with Ruby Hash/Array as params and with the correct content length" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/echo_content_length').post :body => {"key1" => "data1"}

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        
        http.response.to_i.should == 10
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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get 

      http.errback { failed }
      http.stream { |chunk| body += chunk }

      http.callback {
        http.response_header.status.should == 200
        http.response.should == ''
        body.should match(/Hello/)
        EventMachine.stop
      }
    }
  end

  it "should optionally pass the deflate-encoded response body progressively" do
    EventMachine.run {
      body = ''
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/deflate').get :head => {"accept-encoding" => "deflate, compressed"}

      http.errback { failed }
      http.stream { |chunk| body += chunk }

      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "deflate"
        http.response.should == ''
        body.should == "compressed"
        EventMachine.stop
      }
    }
  end

  it "should initiate SSL/TLS on HTTPS connections" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail/').get

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 302
        EventMachine.stop
      }
    }
  end

  it "should accept & return cookie header to user" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/set_cookie').get

      http.errback { failed }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.cookie.should == "id=1; expires=Tue, 09-Aug-2011 17:53:39 GMT; path=/;"
        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/echo_cookie').get :head => {'cookie' => 'id=2;'}

      http.errback { failed }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from Hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/echo_cookie').get :head => {'cookie' => {'id' => 2}}

      http.errback { failed }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

end
