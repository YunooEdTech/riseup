# frozen_string_literal: true

module RiseUp
  class Client
    module Certifications
      BASE = '/certifications'

      # Dead code? No usage found in the codebase.
      def delete
         response = self.class.post("#{@base_uri}/#{BASE}", {
                                      body: { grant_type: "client_credentials" }.to_json,
                                      headers: {
                                        'Authorization' => "Bearer #{access_token}",
                                        'Content-Type' => 'application/json'
                                      }
                                    })
         JSON.parse(response.body)
       end
    end
  end
end
