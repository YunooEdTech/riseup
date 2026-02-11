# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiseUp::Client do
  let(:options) { { public_key: "pk", private_key: "sk" } }
  subject(:client) { described_class.new(options) }

  describe "#request" do
    let(:fake_limiter) { instance_double(RiseUp::TokenBucket, consume: nil) }

    before do
      allow(described_class).to receive(:rate_limiter).and_return(fake_limiter)
    end

    it "calls the rate limiter before performing the request" do
      raw_response = instance_double("Response", code: 200, headers: {}, body: "{}")

      client.request { raw_response }

      expect(fake_limiter).to have_received(:consume).once
    end

    context "when the API responds with 429 and then 200" do
      it "retries the request after handling rate limiting" do
        calls = []

        first_response = instance_double(
          "Response",
          code: 429,
          headers: { "Retry-After" => "1" },
          body: "{}"
        )

        second_response = instance_double(
          "Response",
          code: 200,
          headers: {},
          body: "{}"
        )

        allow(client).to receive(:sleep)

        client.request do
          resp = calls.empty? ? first_response : second_response
          calls << resp.code
          resp
        end

        expect(calls).to eq([429, 200])
        expect(client).to have_received(:sleep).at_least(:once)
      end
    end

    context "when rate limit is exceeded beyond max retries" do
      it "raises an ApiResponseError" do
        response = instance_double(
          "Response",
          code: 429,
          headers: {},
          body: "{}"
        )

        allow(client).to receive(:sleep)

        expect do
          client.request { response }
        end.to raise_error(RiseUp::ApiResponseError, /Rate limit exceeded/)
      end
    end

    context "when token is refreshed and retried" do
      before { allow(client).to receive(:refresh_access_token) }

      it "retries on 401 and succeeds on second attempt" do
        unauthorized_response = instance_double("Response", code: 401, headers: {}, body: "")
        success_response = instance_double("Response", code: 200, headers: {}, body: "{}")
        call_count = 0

        result = client.request do
          call_count += 1
          call_count == 1 ? unauthorized_response : success_response
        end

        expect(call_count).to eq(2)
        expect(result).to be_nil
      end

      it "retries the request on token refresh sentinel error" do
        raw_response = instance_double(
          "Response",
          code: 200,
          headers: {},
          body: "{}"
        )

        call_count = 0

        allow(client).to receive(:handle_errors) do
          if call_count.zero?
            call_count += 1
            raise RiseUp::Errors::RetryableTokenRefresh.new("Token refreshed. Retrying request.")
          end
        end

        client.request { raw_response }

        expect(call_count).to eq(1)
      end

      it "stops retrying after exceeding max token retries" do
        raw_response = instance_double(
          "Response",
          code: 200,
          headers: {},
          body: "{}"
        )

        allow(client).to receive(:handle_errors).and_raise(
          RiseUp::Errors::RetryableTokenRefresh.new("Token refreshed. Retrying request.")
        )

        expect do
          client.request { raw_response }
        end.to raise_error(RiseUp::Errors::TransportError, /Token refresh retries exceeded/)
      end
    end

    context "when a reporting service is provided" do
      let(:reporter) { instance_double("Reporter") }

      subject(:client) { described_class.new(options.merge(reporting_service: reporter)) }

      before do
        allow(reporter).to receive(:report)
      end

      it "reports API errors on final failure" do
        response = instance_double(
          "Response",
          code: 400,
          headers: { "X-Req" => "1" },
          body: '{"error":"invalid_scope","error_description":"bad"}'
        )

        expect do
          client.request { response }
        end.to raise_error(RiseUp::ApiResponseError)

        expect(reporter).to have_received(:report).once do |exception, context:|
          expect(exception).to be_a(RiseUp::ApiResponseError)
          expect(context).to be_a(Hash)
          expect(context[:status]).to eq(400)
        end
      end

      it "does not report 404 API errors" do
        response = instance_double(
          "Response",
          code: 404,
          headers: {},
          body: '{"error":"not_found","error_description":"missing"}'
        )

        expect do
          client.request { response }
        end.to raise_error(RiseUp::ApiResponseError)

        expect(reporter).not_to have_received(:report)
      end

      it "reports JSON parsing errors" do
        response = instance_double(
          "Response",
          code: 200,
          headers: {},
          body: "not-json"
        )

        expect do
          client.request { response }
        end.to raise_error(RiseUp::Errors::TransportError, /Failed to parse JSON/)

        expect(reporter).to have_received(:report).once
      end

      it "does not report internal retries (token refresh / 429 retry)" do
        # token refresh retry
        call_count = 0
        raw_response = instance_double("Response", code: 200, headers: {}, body: "{}")
        allow(client).to receive(:handle_errors) do
          if call_count.zero?
            call_count += 1
            raise RiseUp::Errors::RetryableTokenRefresh.new("Token refreshed. Retrying request.")
          end
        end

        client.request { raw_response }

        # 429 retry path
        calls = []
        first_response = instance_double("Response", code: 429, headers: {}, body: "{}")
        second_response = instance_double("Response", code: 200, headers: {}, body: "{}")
        allow(client).to receive(:sleep)

        client.request do
          resp = calls.empty? ? first_response : second_response
          calls << resp.code
          resp
        end

        expect(reporter).not_to have_received(:report)
      end
    end

    context "when handling JSON and resource wrapping" do
      let(:raw_headers) { { "X-Custom" => "value" } }

      it "wraps array responses into resource instances when wrap_response is true" do
        raw_body = '[{"name":"Alice"},{"name":"Bob"}]'
        raw_response = instance_double("Response", code: 200, headers: raw_headers, body: raw_body)

        stub_const("DummyResource", Class.new(RiseUp::ApiResource::Resource))

        result = client.request(DummyResource, wrap_response: true) { raw_response }

        expect(result.body.length).to eq(2)
        expect(result.body.first).to be_a(DummyResource)
        expect(result.headers).to eq(raw_headers)
      end

      it "returns a single resource instance for hash responses when wrap_response is false" do
        raw_body = '{"name":"Alice"}'
        raw_response = instance_double("Response", code: 200, headers: raw_headers, body: raw_body)

        stub_const("SingleResource", Class.new(RiseUp::ApiResource::Resource))

        result = client.request(SingleResource) { raw_response }

        expect(result).to be_a(SingleResource)
      end
    end
  end
end
