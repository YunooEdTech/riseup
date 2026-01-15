require 'httparty'
require 'ostruct'
require 'rise_up/api_resource/resource'
require 'rise_up/api_resource/certification'
require 'rise_up/api_resource/training_session'
require 'rise_up/api_resource/training_session_registration'
require 'rise_up/api_resource/objective'
require 'rise_up/api_resource/objective_registration'
require 'rise_up/api_resource/objective_level'
require 'rise_up/api_resource/objective_level_user'
require 'rise_up/api_resource/course_request'
require 'rise_up/api_resource/document'
require 'rise_up/api_resource/user'
require 'rise_up/api_resource/course_registration'
require 'rise_up/api_resource/course'
require 'rise_up/api_resource/training_path_subscription'
require 'rise_up/api_resource/training'
require 'rise_up/api_resource/training_path'
require 'rise_up/api_resource/learning_path'
require 'rise_up/api_resource/session'
require 'rise_up/api_resource/module'
require 'rise_up/api_resource/group'
require 'rise_up/api_resource/session_group_subscription'
require 'rise_up/api_resource/custom_field'
require 'rise_up/api_resource/skill'
require 'rise_up/api_resource/training_category'
require 'rise_up/api_resource/session_group'
require 'rise_up/api_resource/learning_path_registration'
require 'rise_up/api_resource/custom_header'
require 'rise_up/api_resource/partner'
require 'rise_up/api_resource/session_subscription'
require 'rise_up/api_resource/classroom_session_registration'
require 'rise_up/utils/token_bucket'
require 'rise_up/client/partners'
require 'rise_up/client/users'
require 'rise_up/client/sessions'
require 'rise_up/client/skills'
require 'rise_up/client/trainings'
require 'rise_up/client/training_paths'
require 'rise_up/client/learning_paths'
require 'rise_up/client/training_path_subscriptions'
require 'rise_up/client/learning_path_registrations'
require 'rise_up/client/session_groups'
require 'rise_up/client/authentication'
require 'rise_up/client/session_group_subscriptions'
require 'rise_up/client/course_registrations'
require 'rise_up/client/courses'
require 'rise_up/client/modules'
require 'rise_up/client/groups'
require 'rise_up/client/custom_fields'
require 'rise_up/client/training_categories'
require 'rise_up/client/custom_headers'
require 'rise_up/client/documents'
require 'rise_up/client/course_requests'
require 'rise_up/client/certifications'
require 'rise_up/client/objectives'
require 'rise_up/client/objective_registrations'
require 'rise_up/client/objective_level_users'
require 'rise_up/client/objective_levels'
require 'rise_up/client/training_session_registrations'
require 'rise_up/client/training_sessions'
require 'rise_up/client/session_subscriptions'
require 'rise_up/client/classroom_session_registrations'

module RiseUp
  class ExpiredTokenError < StandardError; end
  class ApiResponseError < StandardError; end
  class RateLimitRetryError < StandardError; end

  class Client
    include HTTParty
    include RiseUp::Client::Partners
    include RiseUp::Client::Users
    include RiseUp::Client::Authentication
    include RiseUp::Client::CourseRegistrations
    include RiseUp::Client::CourseRequests
    include RiseUp::Client::Certifications
    include RiseUp::Client::Courses
    include RiseUp::Client::TrainingPathSubscriptions
    include RiseUp::Client::Trainings
    include RiseUp::Client::TrainingPaths
    include RiseUp::Client::SessionGroups
    include RiseUp::Client::SessionGroupSubscriptions
    include RiseUp::Client::Sessions
    include RiseUp::Client::Groups
    include RiseUp::Client::CustomFields
    include RiseUp::Client::Modules
    include RiseUp::Client::Skills
    include RiseUp::Client::TrainingCategories
    include RiseUp::Client::CustomHeaders
    include RiseUp::Client::Documents
    include RiseUp::Client::LearningPaths
    include RiseUp::Client::Objectives
    include RiseUp::Client::ObjectiveRegistrations
    include RiseUp::Client::ObjectiveLevelUsers
    include RiseUp::Client::ObjectiveLevels
    include RiseUp::Client::TrainingSessionRegistrations
    include RiseUp::Client::TrainingSessions
    include RiseUp::Client::SessionSubscriptions
    include RiseUp::Client::ClassroomSessionRegistrations

    attr_accessor :public_key, :private_key, :authorization_base_64, :access_token_details, :access_token, :token_storage, :mode

    RATE_LIMIT_CAPACITY = 400
    RATE_LIMIT_REFILL_PER_SECOND = RATE_LIMIT_CAPACITY.to_f / 60.0
    BASE_RATE_LIMIT_DELAYS = [10, 20, 30].freeze

    BASE_URIS = {
      production: {
        aws: 'https://api.riseup.ai/v3',
        ovh: 'https://api.riseup.fr/v3',
        ovh_light: 'https://api.riseup.ovh/v3',
        scw: 'https://fr-par-api.riseup.fr/v3'
      },
      preprod: {
        aws: 'https://preprod-customer-api.riseup.ai/v3',
        ovh: 'https://preprod-customer-api.riseup.fr/v3',
        ovh_light: 'https://preprod-customer-api.riseup.ovh/v3',
        scw: 'https://preprod-customer-api.riseup.scw/v3' # doesnt exist for now - to update when available
      }
    }.freeze

    def initialize(options = {})
        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

      mode = options.fetch(:mode, 'production').to_sym
      cloud = options.fetch(:cloud, 'aws').to_sym
      @base_uri = BASE_URIS.dig(mode, cloud) || BASE_URIS[:production][:aws]

      yield(self) if block_given?
    end

    def init!
      self.authorization_base_64 = Base64.strict_encode64("#{public_key}:#{private_key}")
      self
    end

    # Common method for paginated requests
    def retrieve_with_pagination(resource_name, options = {}, resource_klass = nil)
      url = "#{@base_uri}/#{resource_name}"
      items = []

      loop do
        response = request(resource_klass, wrap_response: true) do
          self.class.get(url, {
            query: options,
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          })
        end

        items.concat(response.body) if response.body

        # Process `Link` header for next page
        link_header = response.headers['Link']
        next_link = extract_next_link(link_header)

        break unless next_link

        url = next_link # Update URL for the next page
      end

      items
    end

    def self.rate_limiter
      # One rate limiter shared by all clients using RiseUp API in the same process
      @rate_limiter ||= TokenBucket.new(
        RATE_LIMIT_CAPACITY,
        RATE_LIMIT_REFILL_PER_SECOND
      )
    end

    def request(resource = nil, wrap_response: false)
      max_token_retries = 2
      max_rate_limit_retries = 3

      token_retries = 0
      rate_limit_retries = 0

      begin
        self.class.rate_limiter.consume

        raw_response = yield

        if handle_rate_limit(raw_response, rate_limit_retries, max_rate_limit_retries)
          rate_limit_retries += 1
          raise RateLimitRetryError, 'Rate limit encountered. Retrying request.'
        end

        parsed_body = JSON.parse(raw_response.body)
        handle_errors(parsed_body)

        if wrap_response
          OpenStruct.new(body: handle_response(parsed_body, resource), headers: raw_response.headers)
        else
          handle_response(parsed_body, resource)
        end
      rescue RateLimitRetryError
        retry
      rescue RuntimeError => e
        if should_retry?(e, token_retries, max_token_retries)
          token_retries += 1
          retry
        else
          raise e
        end
      end
    end

    private

    def handle_response(parsed_body, resource)
      case parsed_body
      when Array
        handle_array_response(parsed_body, resource)
      when Hash
        handle_hash_response(parsed_body, resource)
      else
        parsed_body
      end
    end

    def extract_next_link(link_header)
      return nil unless link_header

      # Extract the URL marked with `rel="next"`
      links = link_header.split(',').map(&:strip)
      next_link = links.find { |link| link.include?('rel="next"') }
      next_link&.match(/<(.+?)>/)&.captures&.first
    end

    def handle_errors(response)
      return unless response.is_a?(Hash)

      return unless response['error']

      if response['error']
        if retryable_error?(response['error'])
          refresh_access_token
          raise 'Token refreshed. Retrying request.'
        else
          raise(ApiResponseError, "#{response['error']} - #{response['error_description']}")
        end
      end
    end

    def retryable_error?(error)
      expired_token?(error) || absent_token?(error) || invalid_token?(error)
    end

    def expired_token?(error)
      error.include?("expired_token")
    end

    def invalid_token?(error)
      error.include?("invalid_token")
    end

    def error_requiring_refresh_token?(response)
      expired_token_error?(response['error']) || absent_token?(response['error']) || missing_expired_error?(response['error_description'])
    end

    def expired_token_error?(error)
      error == "expired_token"
    end

    def absent_token?(error)
      error == 'invalid_request' && self.access_token.nil?
    end

    def missing_expired_error?(error_description)
      error_description == 'Malformed token (missing "expires")'
    end

    def handle_array_response(response, resource)
      response.map{ |item| resource.new(item) } if resource
    end

    def handle_hash_response(response, resource)
      resource.new(response) if resource
    end

    def handle_rate_limit(raw_response, rate_limit_retries, max_rate_limit_retries)
      return false unless raw_response.code.to_i == 429

      if rate_limit_retries < max_rate_limit_retries
        sleep(rate_limit_sleep_seconds(rate_limit_retries))
        true
      else
        raise(ApiResponseError, 'Rate limit exceeded and max retries reached')
      end
    end

    def rate_limit_sleep_seconds(attempt_index)
      base_delay_seconds = BASE_RATE_LIMIT_DELAYS[attempt_index] || BASE_RATE_LIMIT_DELAYS.last
      jitter_factor = 1.0 + (rand * 0.2) # 1.0x–1.2x

      (base_delay_seconds * jitter_factor).round(1)
    end

    def should_retry?(exception, retries, max_retries)
      exception.message == 'Token refreshed. Retrying request.' && retries < max_retries
    end
  end
end
