# #--
# Includes portion originally Copyright (C)2008 Michael Fellinger
# MIT License
# #--

require 'rack'

module Stallion
  class Mount
    def initialize(name, *methods, &block)
      @name, @methods, @block = name, methods, block
    end

    def ride
      @block.call
    end

    def match?(request)
      method = request['REQUEST_METHOD']
      @methods.empty? or @methods.include?(method)
    end
  end

  class Stable
    attr_reader :request, :response

    def initialize
      @boxes = {}
    end

    def in(path, *methods, &block)
      mount = Mount.new(path, *methods, &block)
      @boxes[[path, methods]] = mount
      mount
    end

    def call(request, response)
      @request, @response = request, response
      @boxes.each do |_, mount|
        if mount.match?(request)
          mount.ride
        end
      end
    end
  end

  STABLES = {}

  def self.saddle(name = nil)
    STABLES[name] = stable = Stable.new
    yield stable
  end

  def self.run(options = {})
    options = {:Host => "127.0.0.1", :Port => 8090}.merge(options)
    Rack::Handler::Mongrel.run(Rack::Lint.new(self), options)
  end

  def self.call(env)
    request = Rack::Request.new(env)
    response = Rack::Response.new

    STABLES.each do |name, stable|
      stable.call(request, response)
    end

    response.finish
  end
end

Stallion.saddle :spec do |stable|
  stable.in '/' do

    if stable.request.path_info == '/fail'
      stable.response.status = 404

    elsif stable.request.path_info == '/fail_with_nonstandard_response'
      stable.response.status = 420

    elsif stable.request.query_string == 'q=test'
      stable.response.write 'test'

    elsif stable.request.path_info == '/echo_query'
      stable.response["ETag"] = "abcdefg"
      stable.response["Last-Modified"] = "Fri, 13 Aug 2010 17:31:21 GMT"
      stable.response.write stable.request.query_string

    elsif stable.request.path_info == '/echo_headers'
      stable.response["Set-Cookie"] = "test=yes"
      stable.response["X-Forward-Host"] = "proxy.local"
      stable.response.write stable.request.query_string

    elsif stable.request.path_info == '/echo_content_length'
      stable.response.write stable.request.content_length

    elsif stable.request.path_info == '/echo_content_length_from_header'
      stable.response.write "content-length:#{stable.request.env["CONTENT_LENGTH"]}"

    elsif stable.request.path_info == '/echo_authorization_header'
      stable.response.write "authorization:#{stable.request.env["HTTP_AUTHORIZATION"]}"

    elsif stable.request.head? && stable.request.path_info == '/'
      stable.response.status = 200

    elsif stable.request.delete?
      stable.response.status = 200

    elsif stable.request.put?
      stable.response.write stable.request.body.read

    elsif stable.request.post? || stable.request.patch?
      if stable.request.path_info == '/echo_content_type'
        stable.response["Content-Type"] = stable.request.env["CONTENT_TYPE"] || 'text/html'
        stable.response.write stable.request.env["CONTENT_TYPE"]
      else
        stable.response.write stable.request.body.read
      end

    elsif stable.request.path_info == '/set_cookie'
      stable.response["Set-Cookie"] = "id=1; expires=Sat, 09 Aug 2031 17:53:39 GMT; path=/;"
      stable.response.write "cookie set"

    elsif stable.request.path_info == '/set_multiple_cookies'
      stable.response["Set-Cookie"] = [
        "id=1; expires=Sat, 09 Aug 2031 17:53:39 GMT; path=/;",
        "id=2;"
      ]
      stable.response.write "cookies set"

    elsif stable.request.path_info == '/echo_cookie'
      stable.response.write stable.request.env["HTTP_COOKIE"]

    elsif stable.request.path_info == '/timeout'
      sleep(10)
      stable.response.write 'timeout'

    elsif stable.request.path_info == '/cookie_parrot'
      stable.response.status = 200
      stable.response["Set-Cookie"] = stable.request.env['HTTP_COOKIE']

    elsif stable.request.path_info == '/redirect'
      stable.response.status = 301
      stable.response["Location"] = "/gzip"
      stable.response.write 'redirect'

    elsif stable.request.path_info == '/redirect/created'
      stable.response.status = 201
      stable.response["Location"] = "/"
      stable.response.write  'Hello, World!'

    elsif stable.request.path_info == '/redirect/multiple-with-cookie'
      stable.response.status = 301
      stable.response["Set-Cookie"] = "another_id=1; expires=Sat, 09 Aug 2031 17:53:39 GMT; path=/;"
      stable.response["Location"] = "/redirect"
      stable.response.write 'redirect'

    elsif stable.request.path_info == '/redirect/bad'
      stable.response.status = 301
      stable.response["Location"] = "http://127.0.0.1:8090"

    elsif stable.request.path_info == '/redirect/timeout'
      stable.response.status = 301
      stable.response["Location"] = "http://127.0.0.1:8090/timeout"

    elsif stable.request.path_info == '/redirect/head'
      stable.response.status = 301
      stable.response["Location"] = "/"

    elsif stable.request.path_info == '/redirect/middleware_redirects_1'
      stable.response.status = 301
      stable.response["EM-Middleware"] = stable.request.env["HTTP_EM_MIDDLEWARE"]
      stable.response["Location"] = "/redirect/middleware_redirects_2"

    elsif stable.request.path_info == '/redirect/middleware_redirects_2'
      stable.response.status = 301
      stable.response["EM-Middleware"] = stable.request.env["HTTP_EM_MIDDLEWARE"]
      stable.response["Location"] = "/redirect/middleware_redirects_3"

    elsif stable.request.path_info == '/redirect/middleware_redirects_3'
      stable.response.status = 200
      stable.response["EM-Middleware"] = stable.request.env["HTTP_EM_MIDDLEWARE"]

    elsif stable.request.path_info == '/redirect/nohost'
      stable.response.status = 301
      stable.response["Location"] = "http:/"

    elsif stable.request.path_info == '/redirect/badhost'
      stable.response.status = 301
      stable.response["Location"] = "http://$$$@$!%&^"

    elsif stable.request.path_info == '/redirect/http_no_port'
      stable.response.status = 301
      stable.response["Location"] = "http://host/"

    elsif stable.request.path_info == '/redirect/https_no_port'
      stable.response.status = 301
      stable.response["Location"] = "https://host/"

    elsif stable.request.path_info == '/redirect/http_with_port'
      stable.response.status = 301
      stable.response["Location"] = "http://host:80/"

    elsif stable.request.path_info == '/redirect/https_with_port'
      stable.response.status = 301
      stable.response["Location"] = "https://host:443/"

    elsif stable.request.path_info == '/redirect/ignore_query_option'
      stable.response.status = 301
      stable.response['Location'] = '/redirect/url'

    elsif stable.request.path_info == '/redirect/url'
      stable.response.status = 200
      stable.response.write stable.request.url

    elsif stable.request.path_info == '/gzip'
      io = StringIO.new
      gzip = Zlib::GzipWriter.new(io)
      gzip << "compressed"
      gzip.close

      stable.response.write io.string
      stable.response["Content-Encoding"] = "gzip"

    elsif stable.request.path_info == '/gzip-large'
      contents = File.open(File.dirname(__FILE__) + "/fixtures/gzip-sample.gz", 'r') { |f| f.read }

      stable.response.write contents
      stable.response["Content-Encoding"] = "gzip"

    elsif stable.request.path_info == '/deflate'
      deflater = Zlib::Deflate.new(
        Zlib::DEFAULT_COMPRESSION,
        -Zlib::MAX_WBITS, # drop the zlib header which causes both Safari and IE to choke
        Zlib::DEF_MEM_LEVEL,
        Zlib::DEFAULT_STRATEGY
      )
      deflater.deflate("compressed")
      stable.response.write deflater.finish
      stable.response["Content-Encoding"] = "deflate"

    elsif stable.request.path_info == '/echo_accept_encoding'
      stable.response.status = 200
      stable.response.write stable.request.env["HTTP_ACCEPT_ENCODING"]

    elsif stable.request.env["HTTP_IF_NONE_MATCH"]
      stable.response.status = 304

    elsif stable.request.path_info == '/auth' && stable.request.env["HTTP_AUTHORIZATION"]
      stable.response.status = 200
      stable.response.write stable.request.env["HTTP_AUTHORIZATION"]
    elsif stable.request.path_info == '/authtest'
      auth = "Basic %s" % Base64.strict_encode64(['user', 'pass'].join(':')).split.join
      if auth == stable.request.env["HTTP_AUTHORIZATION"]
        stable.response.status = 200
        stable.response.write 'success'
      else
        stable.response.status = 401
      end
    elsif stable.request.path_info == '/relative-location'
      stable.response.status = 301
      stable.response["Location"] = '/forwarded'
    elsif stable.request.path_info == '/echo-user-agent'
      stable.response.write stable.request.env["HTTP_USER_AGENT"].inspect

    elsif
      stable.response.write  'Hello, World!'
    end

  end
end

Thread.new do
  begin
    Stallion.run :Host => '127.0.0.1', :Port => 8090
  rescue => e
    print e
  end
end

#
# Simple HTTP Proxy server
#
Thread.new do
  server = TCPServer.new('127.0.0.1', 8083)
  loop do
    session = server.accept
    request = ""
    while (data = session.gets) != "\r\n"
      request << data
    end
    parts = request.split("\r\n")
    method, destination, http_version = parts.first.split(' ')
    proxy = parts.find { |part| part =~ /Proxy-Authorization/ }
    if destination =~ /^http:/
      uri = Addressable::URI.parse(destination)
      absolute_path = uri.path + (uri.query ? "?#{uri.query}" : "")
      client = TCPSocket.open(uri.host, uri.port || 80)

      client.write "#{method} #{absolute_path} #{http_version}\r\n"
      parts[1..-1].each do |part|
        client.write "#{part}\r\n"
      end

      client.write "\r\n"
      client.flush
      client.close_write

      # Take the initial line from the upstream response
      session.write client.gets

      if proxy
        session.write "X-Proxy-Auth: #{proxy}\r\n"
      end

      # What (absolute) uri was requested?  Send it back in a header
      session.write "X-The-Requested-URI: #{destination}\r\n"

      while data = client.gets
        session.write data
      end
      session.flush
      client.close
    end
    session.close
  end
end

sleep(1)
