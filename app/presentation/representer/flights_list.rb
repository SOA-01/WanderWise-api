# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'flight'

module WanderWise
  module Representer
    # Represents a collection of flights for JSON API output
    class FlightsRepresenter < Roar::Decorator
      include Roar::JSON

      collection :flights, extend: Representer::FlightRepresenter, class: OpenStruct
    end
  end
end
