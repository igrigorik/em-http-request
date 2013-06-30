require 'multi_json'

module EventMachine
  module Middleware
    class JSONResponse
      def response(resp)
        begin
          body = MultiJson.load(resp.response)
          resp.response = body
        rescue Exception => e
        end
      end
    end
  end
end
