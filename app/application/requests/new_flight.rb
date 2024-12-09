# frozen_string_literal: true

require 'dry-monads'
require 'airports'
require 'date'

module WanderWise
  module Requests
    # Parses and validates HTTP request data for new flight creation
    class NewFlightRequest
      include Dry::Monads::Result::Mixin

      def initialize(params)
        @params = params
      end

      def call
        Success(
          @params
        )
      rescue StandardError
        Failure(
          Response::ApiResult.new(
            status: :bad_request,
            message: 'Results not found'
          )
        )
      end
    end
  end
end
