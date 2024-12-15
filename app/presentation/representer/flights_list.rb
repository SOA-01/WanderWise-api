# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'flight'

module WanderWise
  module Representer
    # Represents a collection of flights for JSON API output
    class Flights < Roar::Decorator
      include Roar::JSON

      collection :flights, extend: Representer::Flight, class: OpenStruct
    end
  end
end
