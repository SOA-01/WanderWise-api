# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module WanderWise
  module Representer
    class MiscData < Roar::Decorator
      include Roar::JSON

      property :historical_average_data
      property :historical_lowest_data
      property :country_data
    end
  end
end
