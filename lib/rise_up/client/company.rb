# frozen_string_literal: true

module RiseUp
  class Client
    module Company
      def company
        request(ApiResource::Resource) do
          self.class.get("#{@base_uri}/company", headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          })
        end
      end
    end
  end
end
