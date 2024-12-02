# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module WanderWise
  module Representer
    # Represents a collection of flights for JSON API output
    class FlightRepresenter < Roar::Decorator
      include Roar::JSON

      property :id
      property :origin_location_code
      property :destination_location_code
      property :departure_date
      property :price
      property :airline
      property :duration
      property :departure_time
      property :arrival_time
    end
  end
end
