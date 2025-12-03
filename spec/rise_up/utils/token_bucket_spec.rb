# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiseUp::TokenBucket do
  let(:capacity) { 2 }
  let(:refill_rate) { 1.0 } # tokens per second

  subject(:bucket) { described_class.new(capacity, refill_rate) }

  describe "#consume" do
    it "consumes tokens without sleeping when enough tokens are available" do
      allow(bucket).to receive(:sleep)

      bucket.consume(1.0)

      expect(bucket).not_to have_received(:sleep)
    end

    it "sleeps when tokens are not available" do
      allow(bucket).to receive(:sleep)

      # Drain all tokens
      bucket.consume(2.0)

      bucket.consume(1.0)

      expect(bucket).to have_received(:sleep).at_least(:once)
    end

    it "refills tokens over time up to capacity" do
      # Drain tokens
      bucket.consume(2.0)

      # Simulate time passing: advance relative to last_refill
      last_refill = bucket.instance_variable_get(:@last_refill)
      allow(bucket).to receive(:current_time).and_return(last_refill + 2.5)
      allow(bucket).to receive(:sleep)

      bucket.consume(1.0)

      # With 2.5 seconds elapsed at 1 token/sec, bucket should have refilled,
      # so no sleep should be needed for this consume
      expect(bucket).not_to have_received(:sleep)
    end
  end
end

