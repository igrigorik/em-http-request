# Changelog

---

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

---