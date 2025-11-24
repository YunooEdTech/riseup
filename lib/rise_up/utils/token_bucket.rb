module RiseUp
  class TokenBucket
    def initialize(capacity:, refill_rate_per_second:)
      @capacity = capacity.to_f
      @refill_rate_per_second = refill_rate_per_second.to_f
      @tokens = @capacity
      @last_refill = current_time
    end

    def consume(tokens = 1.0)
      refill!

      if @tokens >= tokens
        @tokens -= tokens
        return
      end

      tokens_needed = tokens - @tokens
      sleep_seconds = tokens_needed / @refill_rate_per_second
      sleep(sleep_seconds)

      refill!
      @tokens -= tokens
    end

    private

    def refill!
      now = current_time
      elapsed = now - @last_refill
      return if elapsed <= 0

      @tokens = [@capacity, @tokens + elapsed * @refill_rate_per_second].min
      @last_refill = now
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

