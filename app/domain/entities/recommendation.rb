# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'

module WanderWise
  # Represents a recommendation
  class Recommendation < Dry::Struct
    attribute :destination_location_code, Types::String
    attribute :month, Types::Float
    attribute :historical_average_data, Types::Array
    attribute :articles, Types::Array
  end
end
