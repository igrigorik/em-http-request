EM-HTTP-Request
===============

Asynchronous HTTP client for Ruby, based on EventMachine runtime.

- Ragel HTTP parser for speed & performance
- Simple interface for single & parallel requests via deferred callbacks
- Automatic gzip & deflate decoding
- Basic-Auth & OAuth support
- Custom timeout support
- Stream response processing
- Proxy support (with SSL Tunneling): CONNECT, direct & SOCKS5
- Auto-follow 3xx redirects with custom max depth
- Bi-directional communication with web-socket services
- [Native mocking support](http://wiki.github.com/igrigorik/em-http-request/mocking-httprequest) and through [Webmock](http://github.com/bblimke/webmock)

Getting started
---------------

      gem install em-http-request
      irb:0> require 'em-http'

Or checkout [screencast / demo](http://everburning.com/news/eventmachine-screencast-em-http-request/) of using EM-HTTP-Request.

Libraries & Applications using em-http
--------------------------------------

- [chirpstream](http://github.com/joshbuddy/chirpstream) - EM client for Twitters Chirpstream API
- [RDaneel](http://github.com/hasmanydevelopers/RDaneel) - Ruby crawler which respects robots.txt
- [rsolr-async](http://github.com/mwmitchell/rsolr-async) - An asynchronus connection adapter for RSolr
- [PubSubHubbub](http://github.com/igrigorik/PubSubHubbub) - Asynchronous PubSubHubbub ruby client
- [Firering](http://github.com/EmmanuelOga/firering) - Eventmachine powered Campfire API
- and many others.. drop me a link if you want yours included!

Simple client example
---------------------

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://127.0.0.1/').get :query => {'keyname' => 'value'}, :timeout => 10

        http.callback {
          p http.response_header.status
          p http.response_header
          p http.response

          EventMachine.stop
        }
      }

Multi-request example
---------------------

Fire and wait for multiple requests to complete via the MultiRequest interface.

      EventMachine.run {
        multi = EventMachine::MultiRequest.new

        # add multiple requests to the multi-handler
        multi.add(EventMachine::HttpRequest.new('http://www.google.com/').get)
        multi.add(EventMachine::HttpRequest.new('http://www.yahoo.com/').get)

        multi.callback  {
          p multi.responses[:succeeded]
          p multi.responses[:failed]

          EventMachine.stop
        }
      }

Basic-Auth example
------------------

Full basic author support. For OAuth, check examples/oauth-tweet.rb file.

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.website.com/').get :head => {'authorization' => ['user', 'pass']}

        http.errback { failed }
        http.callback {
          p http.response_header
          EventMachine.stop
        }
      }


POSTing data example
--------------------

      EventMachine.run {
        http1 = EventMachine::HttpRequest.new('http://www.website.com/').post :body => {"key1" => 1, "key2" => [2,3]}
        http2 = EventMachine::HttpRequest.new('http://www.website.com/').post :body => "some data"

        # ...
      }

Streaming body processing
-------------------------

Allows you to consume an HTTP stream of content in real-time. Each time a new piece of content is pushed
to the client, it is passed to the stream callback for you to operate on.

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.website.com/').get
        http.stream { |chunk| print chunk }
      }

Streaming files from disk
-------------------------
Allows you to efficiently stream a (large) file from disk via EventMachine's FileStream interface.

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.website.com/').post :file => 'largefile.txt'
        http.callback { |chunk| puts "Upload finished!" }
      }

Proxy example
-------------
Full transparent proxy support with support for SSL tunneling.

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.website.com/').get :proxy => {
          :host => 'www.myproxy.com',
          :port => 8080,
          :authorization => ['username', 'password'] # authorization is optional
      }

SOCKS5 Proxy example
-------------
Tunnel your requests via connect via SOCKS5 proxies (ssh -D port somehost).

    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.website.com/').get :proxy => {
        :host => 'www.myproxy.com',
        :port => 8080,
        :type => :socks
    }

Auto-follow 3xx redirects
-------------------------

Specify the max depth of redirects to follow, default is 0.

      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://www.google.com/').get :redirects => 1
        http.callback { p http.last_effective_url }
      }

WebSocket example
-----------------

[Bi-directional communication with WebSockets](http://www.igvita.com/2009/12/22/ruby-websockets-tcp-for-the-browser/): simply pass in a ws:// resource and the client will negotiate the connection upgrade for you. On successful handshake the callback is invoked, and any incoming messages will be passed to the stream callback. The client can also send data to the server at will by calling the "send" method!

      EventMachine.run {
        http = EventMachine::HttpRequest.new("ws://yourservice.com/websocket").get :timeout => 0

        http.errback { puts "oops" }
        http.callback {
          puts "WebSocket connected!"
          http.send("Hello client")
        }

        http.stream { |msg|
          puts "Recieved: #{msg}"
          http.send "Pong: #{msg}"
        }

        http.disconnect { puts "oops, dropped connection?" }
      }
