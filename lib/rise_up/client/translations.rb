# frozen_string_literal: true

module RiseUp
  class Client
    module Translations
      PATH = '/api-external/translation'
      TIMEOUT = 120

      # Company LMS host, not the public API host. Token refresh, rate limits
      # and error payloads are handled by Client#request.
      def translate(base_url:, language_code:, context:, base_language_code: nil)
        response = request(ApiResource::Resource, wrap_response: true) do
          self.class.post(
            "#{base_url.to_s.chomp('/')}#{PATH}",
            body: {
              languageCode: language_code,
              baseLanguageCode: base_language_code,
              context: context
            }.compact.to_json,
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            },
            timeout: TIMEOUT
          )
        end

        status = response.code.to_i
        unless (200..299).cover?(status)
          raise ApiResponseError.new(
            status: status,
            error: 'translation_failed',
            response_body: response.body,
            response_headers: response.headers
          )
        end

        response.body['translation'].to_s.strip
      end
    end
  end
end
