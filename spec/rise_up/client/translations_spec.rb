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
    it "posts language codes to the company translation route" do
      raw = instance_double("Response", code: 200, headers: {}, body: '{"translation":" Hallo "}')
      allow(described_class).to receive(:post).and_return(raw)

      result = client.translate(
        base_url: "https://client.riseup.ai/",
        language_code: "de",
        base_language_code: "fr",
        context: "Hello"
      )

      expect(result).to eq("Hallo")
      expect(described_class).to have_received(:post).with(
        "https://client.riseup.ai/api-external/translation",
        body: { languageCode: "de", baseLanguageCode: "fr", context: "Hello" }.to_json,
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
        client.translate(base_url: "https://client.riseup.ai", language_code: "de", context: "Hello")
      end.to raise_error(RiseUp::ApiResponseError)
    end
  end
end
