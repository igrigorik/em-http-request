# EM-HTTP-Request

Async (EventMachine) HTTP client. High-level features:

- Asynchronous HTTP API for single & parallel request execution
- Keep-Alive and HTTP pipelining support
- Auto-follow 3xx redirects with max depth
- Automatic gzip & deflate decoding
- Streaming response processing
- Streaming file uploads
- HTTP proxy and SOCKS5 support
- Basic Auth & OAuth
- No native dependencies - works wherever EventMachine runs
- Ryan Dahl's HTTP parser (node.js) via FFI - [http_parser.rb](https://github.com/tmm1/http_parser.rb)

## Getting started

    gem install em-http-request

- Introductory [screencast](http://everburning.com/news/eventmachine-screencast-em-http-request/)
- [Issuing GET/POST/etc requests]()
- [Issuing parallel requests with Multi interface]()
- [Handling Redirects & Timeouts]()
- [Keep-Alive and HTTP Pipelining]()
- [Stream processing responses & uploads]()
- [Issuing requests through HTTP & SOCKS5 proxies]()
- [Basic Auth & OAuth]()

## Extensions

Several higher-order Ruby projects have incorporated em-http and other Ruby HTTP clients:

- [EM-Synchrony](https://github.com/igrigorik/em-synchrony) - Collection of convenience classes and primitives to help untangle evented code (Ruby 1.9 + Fibers).
- [Rack-Client](https://github.com/halorgium/rack-client) - Use Rack API for server, test, and client side. Supports Rack middleware!
    - [Example in action](https://gist.github.com/802391)
- [Faraday](https://github.com/technoweenie/faraday) - Modular HTTP client library using middleware heavily inspired by Rack.
    - [Example in action](https://gist.github.com/802395)

## Testing

- [WebMock](https://github.com/bblimke/webmock) - Library for stubbing and setting expectations on HTTP requests in Ruby.
    - Example of [using WebMock, VCR & EM-HTTP](https://gist.github.com/802553)

## Other libraries & applications using EM-HTTP

- [chirpstream](http://github.com/joshbuddy/chirpstream) - EM client for Twitters Chirpstream API
- [rsolr-async](http://github.com/mwmitchell/rsolr-async) - An asynchronus connection adapter for RSolr
- [PubSubHubbub](http://github.com/igrigorik/PubSubHubbub) - Asynchronous PubSubHubbub ruby client
- [Firering](http://github.com/EmmanuelOga/firering) - Eventmachine powered Campfire API
- [RDaneel](http://github.com/hasmanydevelopers/RDaneel) - Ruby crawler which respects robots.txt
- and many others.. drop me a link if you want yours included!

### License

(MIT License) - Copyright (c) 2011 Ilya Grigorik