require 'yajl'

module EventMachine
  module Middleware
    class JSONResponse
      def response(resp)
        begin
          body = Yajl::Parser.parse(resp.response)
          resp.response = body
        rescue Exception => e
        end
      end
    end
  end
end
