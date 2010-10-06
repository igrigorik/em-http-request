# Changelog

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

