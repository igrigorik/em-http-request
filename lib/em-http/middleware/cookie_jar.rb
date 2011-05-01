require 'cookiejar'

module EventMachine
  module Middleware
    class CookieJar
      class << self
        attr_reader :cookiejar

        def cookiejar=(val)
          @cookiejar = val
        end

        def set_cookie(url, cookie)
          @cookiejar.set_cookie url, cookie
        end
      end

      def request(c, h, r)
        raise ArgumentError, "You may not set cookies outside of the cookie jar" if h.delete('cookie')
        cookies = CookieJar::cookiejar.get_cookie_header(c.last_effective_url)
        h['cookie'] = cookies unless cookies.empty?
        [h, r]
      end

      def response(r)
        cookies = r.response_header.cookie
        if cookies
          [cookies].flatten.each { |c|
            EventMachine::Middleware::CookieJar.cookiejar.set_cookie r.last_effective_url, c
          }
        end
        r.response
     end
    end
  end
end

EventMachine::Middleware::CookieJar.cookiejar = CookieJar::Jar.new
