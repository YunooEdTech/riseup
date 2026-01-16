# frozen_string_literal: true

require "uri"

module RiseUp
  class Client
    module Authentication
      BASE = '/oauth/token'

      def authenticate
        response = self.class.post("#{@base_uri}/#{BASE}", {
                                    body: URI.encode_www_form(grant_type: "client_credentials"),
                                    headers: {
                                      'Authorization' => "Basic #{authorization_base_64}",
                                      'Content-Type' => 'application/x-www-form-urlencoded'
                                    }
                                  })
        response = JSON.parse(response.body)
        self.access_token_details = response
        self.access_token = response["access_token"]
        response
      end

      def refresh_access_token
        response = authenticate
        token_storage.update(
          rise_up_access_token_details: response
        )
        self.access_token = response["access_token"]
        response
      end
    end
  end
end
# curl -X POST \
#   --header "Content-Type: application/x-www-form-urlencoded" \
#   --header "Authorization: Basic insert_your_token_here" \
#   -d "grant_type=client_credentials" \
#   https://preprod-customer-api.riseup.ai/oauth/token