# Changelog

## master

- User-Agent header is now removed if set to nil.

## 1.0.0.beta.1 / 2011-02-20 - The big rewrite

- Switched parser from Ragel to http_parser.rb
- Removed em_buffer C extension
- Added support for HTTP keepalive
- Added support for HTTP pipelining
- ~60% performance improvement across the board: less GC time!
- Refactored & split all tests
- Basic 100-Continue handling on POST/PUT

## 0.3.0 / 2011-01-15

- IMPORTANT: default to non-persistent connections (timeout => 0 now requires :keepalive => true)
- see: https://github.com/igrigorik/em-http-request/commit/1ca5b608e876c18fa6cfa318d0685dcf5b974e09

- added escape_utils dependency to fix slow encode on long string escapes

- bugfix: proxy authorization headers
- bugfix: default to Encoding.default_external on invalid encoding in response
- bugfix: do not normalize URI's internally
- bugfix: more robust Encoding detection


## 0.2.15 / 2010-11-18

- bugfix: follow redirects on missing content-length
- bugfix: fixed undefined warnings when running in strict mode

## 0.2.14 / 2010-10-06

- bugfix: form-encode keys/values of ruby objects passed in as body

## 0.2.13 / 2010-09-25

- added SOCKS5 proxy support
- bugfix: follow redirects on HEAD requests

## 0.2.12 / 2010-09-12

- added headers callback (http.headers {|h| p h})
- added .close method on client obj to terminate session (accepts message)

- bugfix: report 0 for response status on 1.9 on timeouts
- bugfix: handle bad Location host redirects
- bugfix: reset host override on connect

## 0.2.11 / 2010-08-16

- all URIs are now normalized prior to dispatch (and on redirect)
- default to direct proxy (instead of CONNECT handshake) - better performance
  - specify :proxy => {:tunnel => true} if you need to force CONNECT route
- MultiRequest accepts block syntax for dispatching parallel requests (see specs)
- MockHttpRequest accepts block syntax (see Mock wiki page)


- bugfix: nullbyte frame for websockets
- bugfix: set @uri on DNS resolve failure
- bugfix: handle bad hosts in absolute redirects
- bugfix: reset seen content on redirects (doh!)
- bugfix: invalid multibyte escape in websocket regex (1.9.2+)
- bugfix: report etag and last_modified headers correctly

