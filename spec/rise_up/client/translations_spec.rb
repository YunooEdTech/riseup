# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiseUp::Client do
  subject(:client) { described_class.new(public_key: "pk", private_key: "sk") }

  let(:fake_limiter) { instance_double(RiseUp::TokenBucket, consume: nil) }

  before do
    client.access_token = "tok"
    allow(described_class).to receive(:rate_limiter).and_return(fake_limiter)
  end

  describe "#translate" do
    it "posts a batch of texts and returns the translations under the same keys" do
      raw = instance_double(
        "Response",
        code: 200,
        headers: {},
        body: '{"translations":{"title":"Hallo","body":"<p>Siehe</p>"}}'
      )
      allow(described_class).to receive(:post).and_return(raw)

      result = client.translate(
        base_url: "https://client.riseup.ai/",
        texts: { "title" => "Bonjour", "body" => "<p>Voir</p>" },
        target_language_code: "de",
        source_language_code: "fr-FR"
      )

      expect(result).to eq("title" => "Hallo", "body" => "<p>Siehe</p>")
      expect(described_class).to have_received(:post).with(
        "https://client.riseup.ai/api-external/translation",
        body: {
          texts: { "title" => "Bonjour", "body" => "<p>Voir</p>" },
          targetLanguageCode: "de",
          sourceLanguageCode: "fr-FR"
        }.to_json,
        headers: {
          "Authorization" => "Bearer tok",
          "Content-Type" => "application/json"
        },
        timeout: 120
      )
    end

    it "raises when the company rejects the call" do
      raw = instance_double("Response", code: 403, headers: {}, body: "{}")
      allow(described_class).to receive(:post).and_return(raw)

      expect do
        client.translate(base_url: "https://client.riseup.ai", texts: ["Hello"], target_language_code: "de")
      end.to raise_error(RiseUp::ApiResponseError)
    end

    it "raises ApiResponseError when a 403 body is not JSON" do
      raw = instance_double(
        "Response",
        code: 403,
        headers: {},
        body: "<!DOCTYPE html><html><body>Forbidden</body></html>"
      )
      allow(described_class).to receive(:post).and_return(raw)

      expect do
        client.translate(base_url: "https://client.riseup.ai", texts: ["Hello"], target_language_code: "de")
      end.to raise_error(RiseUp::ApiResponseError) { |error| expect(error.status).to eq(403) }
      expect(described_class).to have_received(:post).once
    end
  end
end
