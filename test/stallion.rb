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
      stable.response.write stable.request.query_string

    elsif stable.request.post?
      stable.response.write 'test'

    elsif stable.request.path_info == '/compress'
      stable.response.write Zlib::Deflate.deflate("compressed")
      stable.response["Content-Encoding"] = "gzip"

    elsif stable.request.env["HTTP_IF_NONE_MATCH"]
      stable.response.status = 304

    elsif stable.request.env["HTTP_AUTHORIZATION"]
      auth = "Basic %s" % Base64.encode64(['user', 'pass'].join(':')).chomp

      if auth == stable.request.env["HTTP_AUTHORIZATION"]
        stable.response.status = 200
        stable.response.write 'success'
      else
        stable.response.status = 401
      end

    elsif
      stable.response.write  'Hello, World!'
    end

  end
end

Thread.new do
  Stallion.run :Host => '127.0.0.1', :Port => 8080
end

sleep(2)
