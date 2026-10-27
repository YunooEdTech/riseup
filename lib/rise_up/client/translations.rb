# frozen_string_literal: true

module RiseUp
  class Client
    module Translations
      PATH = '/api-external/translation'
      TIMEOUT = 120

      # Company LMS host, not the public API host. Token refresh, rate limits
      # and error payloads are handled by Client#request.
      # texts is a list, or a map keyed by the caller's own ids. The response
      # translations use those same keys. A text is at most 10_000 characters,
      # 50 texts and 20_000 characters per call.
      def translate(base_url:, texts:, target_language_code:, source_language_code: nil)
        response = request(ApiResource::Resource, wrap_response: true) do
          self.class.post(
            "#{base_url.to_s.chomp('/')}#{PATH}",
            body: {
              texts: texts,
              targetLanguageCode: target_language_code,
              sourceLanguageCode: source_language_code
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

        response.body['translations']
      end
    end
  end
end
