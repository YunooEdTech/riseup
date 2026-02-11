# frozen_string_literal: true

module RiseUp
  module Errors
    # Base error type for errors raised by this gem.
    class Error < StandardError
      attr_reader :context

      def initialize(message = nil, context: {})
        @context = context || {}
        super(message)
      end
    end

    # Error raised when the RiseUp API returns an error payload.
    class ApiError < Error
      attr_reader :status, :error, :error_description, :response_body, :response_headers

      def initialize(
        message = nil,
        status: nil,
        error: nil,
        error_description: nil,
        response_body: nil,
        response_headers: nil,
        context: {}
      )
        @status = status
        @error = error
        @error_description = error_description
        @response_body = response_body
        @response_headers = response_headers

        msg = message || begin
          parts = [error, error_description].compact
          parts.empty? ? "RiseUp API error" : parts.join(" - ")
        end

        super(
          msg,
          context: (context || {}).merge(
            status: status,
            error: error,
            error_description: error_description,
            response_body: response_body,
            response_headers: response_headers
          )
        )
      end
    end

    # Error raised when the HTTP request fails, or when the response cannot be parsed/handled.
    class TransportError < Error; end

    # Internal exception used to trigger a retry after a token refresh.
    # This should never escape Client#request.
    class RetryableTokenRefresh < StandardError
      attr_reader :context

      def initialize(message = nil, context: {})
        @context = context || {}
        super(message)
      end
    end
  end
end

