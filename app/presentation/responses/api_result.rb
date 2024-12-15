# frozen_string_literal: true

require 'dry/monads'

module WanderWise
  module Response
    SUCCESS = Set.new(
      %i[ok created processing no_content]
    ).freeze
    FAILURE = Set.new(
      %i[forbidden not_found bad_request conflict cannot_process
         internal_error]
    ).freeze
    CODES = SUCCESS | FAILURE

    # Response object for any operation result
    ApiResult = Struct.new(:status, :message) do
      def initialize(status:, message:)
        raise(ArgumentError, 'Invalid status') unless CODES.include? status

        super(status, message)
      end

      # Helper methods for wrapping in monads
      def to_success
        Dry::Monads::Success(self)
      end

      def to_failure
        Dry::Monads::Failure(self)
      end
    end
  end
end
