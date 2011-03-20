require 'excon'
require 'httparty'
require 'net/http'
require 'open-uri'
require 'rest_client'
require 'tach'
require 'typhoeus'
require 'sinatra/base'
require 'streamly_ffi'
require 'curb'

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'em-http')

module Benchmark
  class Server < Sinatra::Base

    def self.run
      Rack::Handler::WEBrick.run(
        Benchmark::Server.new,
        :Port => 9292,
        :AccessLog => [],
        :Logger => WEBrick::Log.new(nil, WEBrick::Log::ERROR)
      )
    end

    get '/data/:amount' do |amount|
      'x' * amount.to_i
    end

  end
end

def with_server(&block)
  pid = Process.fork do
    # Benchmark::Server.run
  end
  loop do
    sleep(1)
    begin
      # Excon.get('http://localhost:9292/api/foo')
      break
    rescue
    end
  end
  yield
ensure
  Process.kill(9, pid)
end