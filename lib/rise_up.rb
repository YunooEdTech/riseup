# frozen_string_literal: true

require "rise_up/version"
require "rise_up/errors"
require "rise_up/client"

# https://api.riseup.ai/documentation/
module RiseUp
  class Error < StandardError; end
  class AuthTokenExpiredError < StandardError; end

  # Your code goes here...
end
