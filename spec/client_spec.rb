require 'helper'

describe EventMachine::HttpRequest do

  def failed(http=nil)
    EventMachine.stop
    http ? fail(http.error) : fail
  end

  it "should perform successful GET" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get

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
      http = EventMachine::HttpRequest.new(uri).get

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090').get
      http.callback {
        http.response.should match(/Hello/)
        EventMachine.stop
      }
    }.should_not raise_error

    }
  end

  it "should raise error on invalid URL" do
    EventMachine.run {
      lambda {
      EventMachine::HttpRequest.new('random?text').get
    }.should raise_error(Addressable::URI::InvalidURIError)

    EM.stop
    }
  end

  it "should perform successful HEAD with a URI passed as argument" do
    EventMachine.run {
      uri = URI.parse('http://127.0.0.1:8090/')
      http = EventMachine::HttpRequest.new(uri).head

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
      http = EventMachine::HttpRequest.new(uri).delete

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/fail').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 404
        EventMachine.stop
      }
    }
  end

  it "should return HTTP reason" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/fail').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 404
        http.response_header.http_reason.should == 'Not Found'
        EventMachine.stop
      }
    }
  end

  it "should return HTTP reason 'unknown' on a non-standard status code" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/fail_with_nonstandard_response').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 420
        http.response_header.http_reason.should == 'unknown'
        EventMachine.stop
      }
    }
  end

  it "should build query parameters from Hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get :query => {:q => 'test'}

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get :query => "q=test"

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_query').get :query => {:hash =>['value1','value2']}

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').put :body => "data"

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :body => "data"

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should match(/data/)
        EventMachine.stop
      }
    }
  end

  it "should perform successful PATCH" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').patch :body => "data"

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :body => {:stuff => 'string&string'}

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :body => {"key1" => 1, "key2" => [2,3]}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200

        http.response.should match(/key1=1&key2\[0\]=2&key2\[1\]=3/)
        EventMachine.stop
      }
    }
  end

  it "should set content-length to 0 on posts with empty bodies" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_length_from_header').post

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200

        http.response.strip.split(':')[1].should == '0'
        EventMachine.stop
      }
    }
  end

  it "should perform successful POST with Ruby Hash/Array as params and with the correct content length" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_length').post :body => {"key1" => "data1"}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200

        http.response.to_i.should == 10
        EventMachine.stop
      }
    }
  end

  xit "should support expect-continue header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090').post :body => "data", :head => { 'expect' => '100-continue' }

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == "data"
        EventMachine.stop
      }
    }
  end

  it "should perform successful GET with custom header" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get :head => {'if-none-match' => 'evar!'}

      http.errback { p http; failed(http) }
      http.callback {
        http.response_header.status.should == 304
        EventMachine.stop
      }
    }
  end

  it "should perform basic auth" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/authtest').get :head => {'authorization' => ['user', 'pass']}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should perform basic auth via the URL" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://user:pass@127.0.0.1:8090/authtest').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  it "should return peer's IP address" do
     EventMachine.run {

       conn = EventMachine::HttpRequest.new('http://127.0.0.1:8090/')
       conn.peer.should be_nil

       http = conn.get
       http.peer.should be_nil

       http.errback { failed(http) }
       http.callback {
         conn.peer.should == '127.0.0.1'
         http.peer.should == '127.0.0.1'

         EventMachine.stop
       }
     }
   end

  it "should remove all newlines from long basic auth header" do
    EventMachine.run {
      auth = {'authorization' => ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz']}
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/auth').get :head => auth
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == "Basic YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhOnp6enp6enp6enp6enp6enp6enp6enp6enp6enp6eg=="
        EventMachine.stop
      }
    }
  end

  it "should send proper OAuth auth header" do
    EventMachine.run {
      oauth_header = 'OAuth oauth_nonce="oqwgSYFUD87MHmJJDv7bQqOF2EPnVus7Wkqj5duNByU", b=c, d=e'
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/auth').get :head => {
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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_query').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.etag.should match('abcdefg')
        http.response_header.last_modified.should match('Fri, 13 Aug 2010 17:31:21 GMT')
        EventMachine.stop
      }
    }
  end

  it "should return raw headers in a hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_headers').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.raw['Set-Cookie'].should match('test=yes')
        http.response_header.raw['X-Forward-Host'].should match('proxy.local')
        EventMachine.stop
      }
    }
  end

  it "should detect deflate encoding" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/deflate').get :head => {"accept-encoding" => "deflate"}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "deflate"
        http.response.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should auto-detect and decode gzip encoding" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/gzip').get :head => {"accept-encoding" => "gzip, compressed"}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should stream gzip responses" do
    expected_response = Zlib::GzipReader.open(File.dirname(__FILE__) + "/fixtures/gzip-sample.gz") { |f| f.read }
    actual_response = ''

    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/gzip-large').get :head => {"accept-encoding" => "gzip, compressed"}

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"
        http.response.should == ''

        actual_response.should == expected_response

        EventMachine.stop
      }
      http.stream do |chunk|
        actual_response << chunk
      end
    }
  end

  it "should not decode the response when configured so" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/gzip').get :head => {
        "accept-encoding" => "gzip, compressed"
      }, :decoding => false

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header["CONTENT_ENCODING"].should == "gzip"

        raw = http.response
        Zlib::GzipReader.new(StringIO.new(raw)).read.should == "compressed"

        EventMachine.stop
      }
    }
  end

  it "should default to requesting compressed response" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_accept_encoding').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == "gzip, compressed"

        EventMachine.stop
      }
    }
  end

  it "should default to requesting compressed response" do
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_accept_encoding').get :compressed => false

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == ""

        EventMachine.stop
      }
    }
  end

  it "should timeout after 0.1 seconds of inactivity" do
    EventMachine.run {
      t = Time.now.to_i
      EventMachine.heartbeat_interval = 0.1
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/timeout', :inactivity_timeout => 0.1).get

      http.errback {
        http.error.should == Errno::ETIMEDOUT
        (Time.now.to_i - t).should <= 1
        EventMachine.stop
      }
      http.callback { failed(http) }
    }
  end

  it "should complete a Location: with a relative path" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/relative-location').get

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
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_type').post :body => "data"

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
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_type').post :body => {:a => :b}

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
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_type').post({
          :body => {:a => :b}, :head => {'content-type' => ct}})

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.content_charset.should == Encoding.find('utf-8') if defined? Encoding
            http.response_header["CONTENT_TYPE"].should == ct
            EventMachine.stop
          }
      }
    end

    it "should default to external encoding on invalid encoding" do
      EventMachine.run {
        ct = 'text/html; charset=utf-8lias'
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_type').post({
          :body => {:a => :b}, :head => {'content-type' => ct}})

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.content_charset.should == Encoding.find('utf-8') if defined? Encoding
            http.response_header["CONTENT_TYPE"].should == ct
            EventMachine.stop
          }
      }
    end

    it "should processed escaped content-type" do
      EventMachine.run {
        ct = "text/html; charset=\"ISO-8859-4\""
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_content_type').post({
          :body => {:a => :b}, :head => {'content-type' => ct}})

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.content_charset.should == Encoding.find('ISO-8859-4') if defined? Encoding
            http.response_header["CONTENT_TYPE"].should == ct
            EventMachine.stop
          }
      }
    end
  end

  context "optional header callback" do
    it "should optionally pass the response headers" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get

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
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').get

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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/deflate').get :head => {
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
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/set_cookie').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.cookie.should == "id=1; expires=Sat, 09 Aug 2031 17:53:39 GMT; path=/;"
        EventMachine.stop
      }
    }
  end

  it "should return array of cookies on multiple Set-Cookie headers" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/set_multiple_cookies').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.cookie.size.should == 2
        http.response_header.cookie.first.should == "id=1; expires=Sat, 09 Aug 2031 17:53:39 GMT; path=/;"
        http.response_header.cookie.last.should == "id=2;"

        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from string" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_cookie').get :head => {'cookie' => 'id=2;'}

      http.errback { failed(http) }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

  it "should pass cookie header to server from Hash" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo_cookie').get :head => {'cookie' => {'id' => 2}}

      http.errback { failed(http) }
      http.callback {
        http.response.should == "id=2;"
        EventMachine.stop
      }
    }
  end

  it "should get the body without Content-Length" do
    EventMachine.run {
      @s = StubServer.new("HTTP/1.1 200 OK\r\n\r\nFoo")

      http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
      http.errback { failed(http) }
      http.callback {
        http.response.should match(/Foo/)
        http.response_header['CONTENT_LENGTH'].should be_nil

        @s.stop
        EventMachine.stop
      }
    }
  end

  context "when talking to a stub HTTP/1.0 server" do
    it "should get the body without Content-Length" do

      EventMachine.run {
        @s = StubServer.new("HTTP/1.0 200 OK\r\nConnection: close\r\n\r\nFoo")

        http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
        http.errback { failed(http) }
        http.callback {
          http.response.should match(/Foo/)
          http.response_header['CONTENT_LENGTH'].should be_nil

          @s.stop
          EventMachine.stop
        }
      }
    end

    it "should work with \\n instead of \\r\\n" do
      EventMachine.run {
        @s = StubServer.new("HTTP/1.0 200 OK\nContent-Type: text/plain\nContent-Length: 3\nConnection: close\n\nFoo")

        http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
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

    it "should handle invalid HTTP response" do
      EventMachine.run {
        @s = StubServer.new("<html></html>")

        http = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
        http.callback { failed(http) }
        http.errback {
          http.error.should_not be_nil
          EM.stop
        }
      }
    end
  end

  it "should stream a file off disk" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :file => 'spec/fixtures/google.ca'

      http.errback { failed(http) }
      http.callback {
        http.response.should match('google')
        EventMachine.stop
      }
    }
  end

  it "streams POST request from disk via Pathname" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :body => Pathname.new('spec/fixtures/google.ca')
      http.errback { failed(http) }
      http.callback {
        http.response.should match('google')
        EventMachine.stop
      }
    }
  end

  it "streams POST request from IO object" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/').post :body => StringIO.new(File.read('spec/fixtures/google.ca'))
      http.errback { failed(http) }
      http.callback {
        http.response.should match('google')
        EventMachine.stop
      }
    }
  end

  it "should reconnect if connection was closed between requests" do
    EventMachine.run {
      conn = EM::HttpRequest.new('http://127.0.0.1:8090/')
      req = conn.get

      req.callback do
        conn.close('client closing connection')

        EM.next_tick do
          req = conn.get :path => "/gzip"
          req.callback do
            req.response_header.status.should == 200
            req.response.should match('compressed')
            EventMachine.stop
          end
        end
      end
    }
  end

  it "should report error if connection was closed by server on client keepalive requests" do
    EventMachine.run {
      conn = EM::HttpRequest.new('http://127.0.0.1:8090/')
      req = conn.get :keepalive => true

      req.callback do
        req = conn.get

        req.callback { failed(http) }
        req.errback do
          req.error.should match('connection closed by server')
          EventMachine.stop
        end
      end
    }
  end

  it 'should handle malformed Content-Type header repetitions' do
    EventMachine.run {
      response =<<-HTTP.gsub(/^ +/, '').strip
        HTTP/1.0 200 OK
        Content-Type: text/plain; charset=iso-8859-1
        Content-Type: text/plain; charset=utf-8
        Content-Length: 5
        Connection: close

        Hello
      HTTP

      @s       = StubServer.new(response)
      http     = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
      http.errback { failed(http) }
      http.callback {
        http.content_charset.should == Encoding::ISO_8859_1 if defined? Encoding
        EventMachine.stop
      }
    }
  end

  it "should allow indifferent access to headers" do
    EventMachine.run {
      response =<<-HTTP.gsub(/^ +/, '').strip
        HTTP/1.0 200 OK
        Content-Type: text/plain; charset=utf-8
        X-Custom-Header: foo
        Content-Length: 5
        Connection: close

        Hello
      HTTP

      @s       = StubServer.new(response)
      http     = EventMachine::HttpRequest.new('http://127.0.0.1:8081/').get
      http.errback { failed(http) }
      http.callback {
        http.response_header["Content-Type"].should == "text/plain; charset=utf-8"
        http.response_header["CONTENT_TYPE"].should == "text/plain; charset=utf-8"

        http.response_header["Content-Length"].should == "5"
        http.response_header["CONTENT_LENGTH"].should == "5"

        http.response_header["X-Custom-Header"].should == "foo"
        http.response_header["X_CUSTOM_HEADER"].should == "foo"

        EventMachine.stop
      }
    }
  end

  it "should close connection on invalid HTTP response" do
    EventMachine.run {
      response =<<-HTTP.gsub(/^ +/, '').strip
        HTTP/1.1 403 Forbidden
        Content-Type: text/plain
        Content-Length: 13

        Access Denied

        HTTP/1.1 403 Forbidden
        Content-Type: text/plain
        Content-Length: 13

        Access Denied
      HTTP

      @s = StubServer.new(response)
      lambda {
        conn = EventMachine::HttpRequest.new('http://127.0.0.1:8081/')
        req = conn.get
        req.errback { failed(http) }
        req.callback { EM.stop }
      }.should_not raise_error

    }
  end

  context "User-Agent" do
    it 'should default to "EventMachine HttpClient"' do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo-user-agent').get

        http.errback { failed(http) }
        http.callback {
          http.response.should == '"EventMachine HttpClient"'
          EventMachine.stop
        }
      }
    end

    it 'should keep header if given empty string' do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo-user-agent').get(:head => { 'user-agent'=>'' })

        http.errback { failed(http) }
        http.callback {
          http.response.should == '""'
          EventMachine.stop
        }
      }
    end

    it 'should ommit header if given nil' do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/echo-user-agent').get(:head => { 'user-agent'=>nil })

        http.errback { failed(http) }
        http.callback {
          http.response.should == 'nil'
          EventMachine.stop
        }
      }
    end
  end

  context "IPv6" do
    it "should perform successful GET" do
      EventMachine.run {
        @s = StubServer.new({
          response: "HTTP/1.1 200 OK\r\n\r\nHello IPv6",
          port: 8091,
          host: '::1',
        })
        http = EventMachine::HttpRequest.new('http://[::1]:8091/').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response.should match(/Hello IPv6/)
          EventMachine.stop
        }
      }
    end
  end
end
