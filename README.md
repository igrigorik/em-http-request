# EM-HTTP-Request 

[![Gem Version](https://badge.fury.io/rb/ably-em-http-request.svg)](http://rubygems.org/gems/ably-em-http-request)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ably-forks/em-http-request/ci.yml)](https://github.com/ably-forks/em-http-request/actions/workflows/ci.yml)

**Note:** This is Ably’s fork of https://github.com/igrigorik/em-http-request. We created it to fix a TLS-related issue in the original library, which seems to be no longer maintained. This fork exists to be used inside our [ably-ruby SDK](https://github.com/ably/ably-ruby). We have only made the changes required to be able to distribute this library as a separate gem; in particular, most of the documentation still refers to the original library. The constant names used in this fork have been changed so as not to clash with the original library.

Async (EventMachine) HTTP client, with support for:

- Asynchronous HTTP API for single & parallel request execution
- Keep-Alive and HTTP pipelining support
- Auto-follow 3xx redirects with max depth
- Automatic gzip & deflate decoding
- Streaming response processing
- Streaming file uploads
- HTTP proxy and SOCKS5 support
- Basic Auth & OAuth
- Connection-level & global middleware support
- HTTP parser via [http_parser.rb](https://github.com/tmm1/http_parser.rb)
- Works wherever EventMachine runs: Rubinius, JRuby, MRI

## Getting started

    gem install ably-em-http-request

- Introductory [screencast](http://everburning.com/news/eventmachine-screencast-em-http-request)
- [Issuing GET/POST/etc requests](https://github.com/igrigorik/em-http-request/wiki/Issuing-Requests)
- [Issuing parallel requests with Multi interface](https://github.com/igrigorik/em-http-request/wiki/Parallel-Requests)
- [Handling Redirects & Timeouts](https://github.com/igrigorik/em-http-request/wiki/Redirects-and-Timeouts)
- [Keep-Alive and HTTP Pipelining](https://github.com/igrigorik/em-http-request/wiki/Keep-Alive-and-HTTP-Pipelining)
- [Stream processing responses & uploads](https://github.com/igrigorik/em-http-request/wiki/Streaming)
- [Issuing requests through HTTP & SOCKS5 proxies](https://github.com/igrigorik/em-http-request/wiki/Proxy)
- [Basic Auth & OAuth](https://github.com/igrigorik/em-http-request/wiki/Basic-Auth-and-OAuth)
- [GZIP & Deflate decoding](https://github.com/igrigorik/em-http-request/wiki/Compression)
- [EM-HTTP Middleware](https://github.com/igrigorik/em-http-request/wiki/Middleware)

## Extensions

Several higher-order Ruby projects have incorporated em-http and other Ruby HTTP clients:

- [EM-Synchrony](https://github.com/igrigorik/em-synchrony) - Collection of convenience classes and primitives to help untangle evented code (Ruby 1.9 + Fibers).
- [Rack-Client](https://github.com/halorgium/rack-client) - Use Rack API for server, test, and client side. Supports Rack middleware!
    - [Example in action](https://gist.github.com/802391)
- [Faraday](https://github.com/lostisland/faraday) - Modular HTTP client library using middleware heavily inspired by Rack.
    - [Example in action](https://gist.github.com/802395)

## Testing

- [WebMock](https://github.com/bblimke/webmock) - Library for stubbing and setting expectations on HTTP requests in Ruby.
    - Example of [using WebMock, VCR & EM-HTTP](https://gist.github.com/802553)

## Other libraries & applications using EM-HTTP

- [VMWare CloudFoundry](https://github.com/cloudfoundry) - The open platform-as-a-service project
- [PubSubHubbub](https://github.com/igrigorik/PubSubHubbub) - Asynchronous PubSubHubbub ruby client
- [em-net-http](https://github.com/jfairbairn/em-net-http) - Monkeypatching Net::HTTP to play ball with EventMachine
- [chirpstream](https://github.com/joshbuddy/chirpstream) - EM client for Twitters Chirpstream API
- [rsolr-async](https://github.com/mwmitchell/rsolr-async) - An asynchronus connection adapter for RSolr
- [Firering](https://github.com/EmmanuelOga/firering) - Eventmachine powered Campfire API
- [RDaneel](https://github.com/hasmanydevelopers/RDaneel) - Ruby crawler which respects robots.txt
- [em-eventsource](https://github.com/AF83/em-eventsource) - EventSource client for EventMachine
- and many others.. drop me a link if you want yours included!

## Release process

(Added for Ably’s fork.)

This library uses [semantic versioning](http://semver.org/). For each release, the following needs to be done:

- Update the version number in [version.rb](./lib/em-http-request/vesrion.rb) and commit the change.
- TODO how to do CHANGELOG
- Create and push a tag named by prefixing the version number with the letter `v`; e.g. `git tag v1.1.8 && git push origin v1.1.8`.
- Visit [https://github.com/ably-forks/em-http-request/tags](https://github.com/ably-forks/em-http-request/tags) and `Add release notes` for the release including links to the changelog entry.
* Run `rake release` to publish the gem to [Rubygems](https://rubygems.org/gems/ably-em-http-request).

### License

(MIT License) - Copyright (c) 2011 Ilya Grigorik
