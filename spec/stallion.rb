# #--
# Includes portion originally Copyright (C)2008 Michael Fellinger
# license See file LICENSE for details
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
      right_method = @methods.empty? or @methods.include?(method)
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
      @boxes.each do |(path, methods), mount|
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
    options = {:Host => "127.0.0.1", :Port => 8080}.merge(options)
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

    elsif stable.request.query_string == 'q=test'
      stable.response.write 'test'

    elsif stable.request.path_info == '/echo_query'
      stable.response["ETag"] = "abcdefg"
      stable.response["Last-Modified"] = "Fri, 13 Aug 2010 17:31:21 GMT"
      stable.response.write stable.request.query_string

    elsif stable.request.path_info == '/echo_content_length'
      stable.response.write stable.request.content_length

    elsif stable.request.head? && stable.request.path_info == '/'
      stable.response.status = 200

    elsif stable.request.delete?
      stable.response.status = 200

    elsif stable.request.put?
      stable.response.write stable.request.body.read

    elsif stable.request.post?
      if stable.request.path_info == '/echo_content_type'
        stable.response.write stable.request.env["CONTENT_TYPE"]
      else
        stable.response.write stable.request.body.read
      end

    elsif stable.request.path_info == '/set_cookie'
      stable.response["Set-Cookie"] = "id=1; expires=Tue, 09-Aug-2011 17:53:39 GMT; path=/;"
      stable.response.write "cookie set"

    elsif stable.request.path_info == '/echo_cookie'
      stable.response.write stable.request.env["HTTP_COOKIE"]

    elsif stable.request.path_info == '/timeout'
      sleep(10)
      stable.response.write 'timeout'

    elsif stable.request.path_info == '/redirect'
      stable.response.status = 301
      stable.response["Location"] = "/gzip"
      stable.response.write 'redirect'

    elsif stable.request.path_info == '/redirect/bad'
      stable.response.status = 301
      stable.response["Location"] = "http://127.0.0.1:8080"

    elsif stable.request.path_info == '/redirect/head'
      stable.response.status = 301
      stable.response["Location"] = "/"

    elsif stable.request.path_info == '/redirect/nohost'
      stable.response.status = 301
      stable.response["Location"] = "http:/"

    elsif stable.request.path_info == '/redirect/badhost'
      stable.response.status = 301
      stable.response["Location"] = "http://$$$@$!%&^"

    elsif stable.request.path_info == '/gzip'
      io = StringIO.new
      gzip = Zlib::GzipWriter.new(io)
      gzip << "compressed"
      gzip.close

      stable.response.write io.string
      stable.response["Content-Encoding"] = "gzip"

    elsif stable.request.path_info == '/deflate'
      stable.response.write Zlib::Deflate.deflate("compressed")
      stable.response["Content-Encoding"] = "deflate"

    elsif stable.request.env["HTTP_IF_NONE_MATCH"]
      stable.response.status = 304

    elsif stable.request.env["HTTP_AUTHORIZATION"]
      if stable.request.path_info == '/oauth_auth'
        stable.response.status = 200
        stable.response.write stable.request.env["HTTP_AUTHORIZATION"]
      else
        auth = "Basic %s" % Base64.encode64(['user', 'pass'].join(':')).chomp

        if auth == stable.request.env["HTTP_AUTHORIZATION"]
          stable.response.status = 200
          stable.response.write 'success'
        else
          stable.response.status = 401
        end
      end
    elsif stable.request.path_info == '/relative-location'
      stable.response.status = 301
      stable.response["Location"] = '/forwarded'

    elsif
      stable.response.write  'Hello, World!'
    end

  end
end

Thread.new do
  begin
    Stallion.run :Host => '127.0.0.1', :Port => 8080
  rescue Exception => e
    print e
  end
end

#
# Tunneling HTTP Proxy server
#
Thread.new do
  server = TCPServer.new('127.0.0.1', 8082)
  loop do
    session = server.accept
    request = ""
    while (data = session.gets) != "\r\n"
      request << data
    end
    parts = request.split("\r\n")
    method, destination, http_version = parts.first.split(' ')
    if method == 'CONNECT'
      target_host, target_port = destination.split(':')
      client = TCPSocket.open(target_host, target_port)
      session.write "HTTP/1.1 200 Connection established\r\nProxy-agent: Whatever\r\n\r\n"
      session.flush

      content_length = -1
      verb = ""
      req = ""

      while data = session.gets
        if request = data.match(/(\w+).*HTTP\/1\.1/)
          verb = request[1]
        end

        if post = data.match(/Content-Length: (\d+)/)
          content_length = post[1].to_i
        end

        req += data

        # read POST data
        if data == "\r\n" and verb == "POST"
          req += session.read(content_length)
        end

        if data == "\r\n"
          client.write req
          client.flush
          client.close_write
          break
        end
      end

      while data = client.gets
        session.write data
      end
      session.flush
      client.close
    end
    session.close
  end
end

#
# CONNECT-less HTTP Proxy server
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
