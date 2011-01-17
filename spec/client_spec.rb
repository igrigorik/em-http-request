require 'helper'

describe EventMachine::HttpRequest do

  def failed(http=nil)
    EventMachine.stop
    http ? fail(http.error) : fail
  end

  it "should perform successful GET" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/Hello/)
        EventMachine.stop
      }
    }
  end

  it "should perform successful GET with a URI passed as argument" do
    EventMachine.run {
      uri = URI.parse('http://127.0.0.1:8090/')
      http = EventMachine::HttpRequest.connect(uri).get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/Hello/)
        EventMachine.stop
      }
    }
  end

  it "should succeed GET on missing path" do
    EventMachine.run {
      lambda {
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090').get
        http.callback {
          http.response.should match(/Hello/)
          EventMachine.stop
        }
      }.should_not raise_error(ArgumentError)

    }
  end

  it "should raise error on invalid URL" do
    EventMachine.run {
      lambda {
        EventMachine::HttpRequest.connect('random?text').get
      }.should raise_error

      EM.stop
    }
  end

  it "should perform successful HEAD with a URI passed as argument" do
    EventMachine.run {
      uri = URI.parse('http://127.0.0.1:8090/')
      http = EventMachine::HttpRequest.connect(uri).head

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == ""
        EventMachine.stop
      }
    }
  end

  it "should perform successful DELETE with a URI passed as argument" do
    EventMachine.run {
      uri = URI.parse('http://127.0.0.1:8090/')
      http = EventMachine::HttpRequest.connect(uri).delete

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == ""
        EventMachine.stop
      }
    }
  end

  it "should return 404 on invalid path" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/fail').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 404
        EventMachine.stop
      }
    }
  end

  it "should build query parameters from Hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get :query => {:q => 'test'}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/test/)
        EventMachine.stop
      }
    }
  end

  it "should pass query parameters string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get :query => "q=test"

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/test/)
        EventMachine.stop
      }
    }
  end

  it "should encode an array of query parameters" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_query').get :query => {:hash =>['value1','value2']}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/hash\[\]=value1&hash\[\]=value2/)
        EventMachine.stop
      }
    }
  end

  it "should perform successful PUT" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').put :body => "data"

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/data/)
        EventMachine.stop
      }
    }
  end

  it "should perform successful POST" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').post :body => "data"

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/data/)
        EventMachine.stop
      }
    }
  end

  it "should escape body on POST" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').post :body => {:stuff => 'string&string'}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == "stuff=string%26string"
        EventMachine.stop
      }
    }
  end

  it "should perform successful POST with Ruby Hash/Array as params" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').post :body => {"key1" => 1, "key2" => [2,3]}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200

        http.response.should match(/key1=1&key2\[0\]=2&key2\[1\]=3/)
        EventMachine.stop
      }
    }
  end

  it "should perform successful POST with Ruby Hash/Array as params and with the correct content length" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_length').post :body => {"key1" => "data1"}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200

        http.response.to_i.should == 10
        EventMachine.stop
      }
    }
  end

  it "should perform successful GET with custom header" do
    EventMachine.run {
      pending "unbinds before it calls complete_request -- need extra checks"
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get :head => {'if-none-match' => 'evar!'}

      http.errback { p http; failed(http) }
      http.callback {
        http.response_header.status.should == 304
        EventMachine.stop
      }
    }
  end

  it "should perform basic auth" do
    EventMachine.run {

      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get :head => {'authorization' => ['user', 'pass']}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should send proper OAuth auth header" do
    EventMachine.run {
      oauth_header = 'OAuth oauth_nonce="oqwgSYFUD87MHmJJDv7bQqOF2EPnVus7Wkqj5duNByU", b=c, d=e'
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/oauth_auth').get :head => {
        'authorization' => oauth_header
      }

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == oauth_header
        EventMachine.stop
      }
    }
  end

  it "should return ETag and Last-Modified headers" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_query').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.etag.should match('abcdefg')
        http.response_header.last_modified.should match('Fri, 13 Aug 2010 17:31:21 GMT')
        EventMachine.stop
      }
    }
  end

  it "should detect deflate encoding" do
    EventMachine.run {

      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/deflate').get :head => {"accept-encoding" => "deflate"}

      http.errback { failed(http) }
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

      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/gzip').get :head => {
        "accept-encoding" => "gzip, compressed"
      }

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should timeout after 1 second" do
    EventMachine.run {
      t = Time.now.to_i
      EventMachine.heartbeat_interval = 0.1
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/timeout', :timeout => 0.1).get

      http.errback {
        (Time.now.to_i - t).should <= 5
        EventMachine.stop
      }
      http.callback { failed(http) }
    }
  end

  it "should complete a Location: with a relative path" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/relative-location').get

      http.errback { failed(http) }
      http.callback {
        http.response_header['LOCATION'].should == 'http://127.0.0.1:8090/forwarded'
        EventMachine.stop
      }
    }
  end

  context "body content-type encoding" do
    it "should not set content type on string in body" do
      EventMachine.run {
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_type').post :body => "data"

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should be_empty
          EventMachine.stop
        }
      }
    end

    it "should set content-type automatically when passed a ruby hash/array for body" do
      EventMachine.run {
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_type').post :body => {:a => :b}

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should match("application/x-www-form-urlencoded")
          EventMachine.stop
        }
      }
    end

    it "should not override content-type when passing in ruby hash/array for body" do
      EventMachine.run {
        ct = 'text; charset=utf-8'
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_type').post({
        :body => {:a => :b}, :head => {'content-type' => ct}})

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.content_charset.should == Encoding.find('utf-8')
          http.response_header["CONTENT_TYPE"].should == ct
          EventMachine.stop
        }
      }
    end

    it "should default to external encoding on invalid encoding" do
      EventMachine.run {
        ct = 'text/html; charset=utf-8lias'
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_type').post({
        :body => {:a => :b}, :head => {'content-type' => ct}})

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.content_charset.should == Encoding.find('utf-8')
          http.response_header["CONTENT_TYPE"].should == ct
          EventMachine.stop
        }
      }
    end

    it "should processed escaped content-type" do
      EventMachine.run {
        ct = "text/html; charset=\"ISO-8859-4\""
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_content_type').post({
        :body => {:a => :b}, :head => {'content-type' => ct}})

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.content_charset.should == Encoding.find('ISO-8859-4')
          http.response_header["CONTENT_TYPE"].should == ct
          EventMachine.stop
        }
      }
    end
  end

  context "host override" do
    it "should accept optional host" do
      EventMachine.run {
        http = EventMachine::HttpRequest.connect('http://google.com:8090/', :host => '127.0.0.1').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should match(/Hello/)
          EventMachine.stop
        }
      }
    end
  end

  context "optional header callback" do
    it "should optionally pass the response headers" do
      EventMachine.run {
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get

        http.errback { failed(http) }
        http.headers { |hash|
          hash.should be_an_kind_of Hash
          hash.should include 'CONNECTION'
          hash.should include 'CONTENT_LENGTH'
        }

        http.callback {
          http.response_header.status.should == 200
          http.response.should match(/Hello/)
          EventMachine.stop
        }
      }
    end

    it "should allow to terminate current connection from header callback" do
      EventMachine.run {
        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get

        http.callback { failed(http) }
        http.headers { |hash|
          hash.should be_an_kind_of Hash
          hash.should include 'CONNECTION'
          hash.should include 'CONTENT_LENGTH'

          http.close('header callback terminated connection')
        }

        http.errback { |e|
          http.response_header.status.should == 200
          http.error.should == 'header callback terminated connection'
          http.response.should == ''
          EventMachine.stop
        }
      }
    end
  end

  it "should optionally pass the response body progressively" do
    EventMachine.run {
      body = ''
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').get

      http.errback { failed(http) }
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
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/deflate').get :head => {
        "accept-encoding" => "deflate, compressed"
      }

      http.errback { failed(http) }
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

  it "should accept & return cookie header to user" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/set_cookie').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.cookie.should == "id=1; expires=Tue, 09-Aug-2011 17:53:39 GMT; path=/;"
        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_cookie').get :head => {'cookie' => 'id=2;'}

      http.errback { failed(http) }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from Hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/echo_cookie').get :head => {'cookie' => {'id' => 2}}

      http.errback { failed(http) }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

  context "when talking to a stub HTTP/1.0 server" do
    it "should get the body without Content-Length" do
      pending "need to fix parser"

      EventMachine.run {
        @s = StubServer.new("HTTP/1.0 200 OK\r\nConnection: close\r\n\r\nFoo")

        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8081/').get
        http.errback { failed(http) }
        http.callback {
          http.response.should match(/Foo/)
          http.response_header['CONTENT_LENGTH'].should_not == 0

          @s.stop
          EventMachine.stop
        }
      }
    end

    it "should work with \\n instead of \\r\\n" do
      EventMachine.run {
        @s = StubServer.new("HTTP/1.0 200 OK\nContent-Type: text/plain\nContent-Length: 3\nConnection: close\n\nFoo")

        http = EventMachine::HttpRequest.connect('http://127.0.0.1:8081/').get
        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response_header['CONTENT_TYPE'].should == 'text/plain'
          http.response.should match(/Foo/)

          @s.stop
          EventMachine.stop
        }
      }
    end
  end

  it "should stream a file off disk" do
    EventMachine.run {
      http = EventMachine::HttpRequest.connect('http://127.0.0.1:8090/').post :file => 'spec/fixtures/google.ca'

      http.errback { failed(http) }
      http.callback {
        http.response.should match('google')
        EventMachine.stop
      }
    }
  end

end
