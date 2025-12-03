module RiseUp
  class TokenBucket
    # Principle :
    # The bucket is refilled at a rate of @refill_rate_per_second tokens per second.
    # The rate is fixed and represents an average. It is not a sliding window that mirrors the actual rate of consumption.
    # If the bucket is not consumed for a while, it will be refilled to the @capacity.
    # If the bucket is consumed, it will be depleted by the number of tokens consumed.
    # If the bucket doesn't have enough tokens, the request will sleep for the number of seconds needed to refill the bucket.

    def initialize(capacity, refill_rate_per_second)
      @capacity = capacity.to_f
      @refill_rate_per_second = refill_rate_per_second.to_f
      @tokens_available = @capacity
      @last_refill = current_time
    end

    def consume(tokens = 1.0)
      refill!

      sleep_and_refill!(tokens) if !can_consume?(tokens)

      @tokens_available -= tokens # Green light : the bucket has enough tokens, we can consume the tokens.
    end

    private

    def can_consume?(tokens)
      @tokens_available >= tokens
    end

    def sleep_and_refill!(tokens)
      # Red light : the bucket has not enough tokens, we need to sleep to refill the bucket.
      tokens_needed = tokens - @tokens_available
      sleep_seconds = tokens_needed / @refill_rate_per_second
      sleep(sleep_seconds)
      refill!
    end

    def refill!
      now = current_time
      elapsed = now - @last_refill
      return if elapsed <= 0

      @tokens_available = [@capacity, @tokens_available + elapsed * @refill_rate_per_second].min
      @last_refill = now
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

