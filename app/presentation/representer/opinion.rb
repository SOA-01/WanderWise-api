# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'
require 'roar/hypermedia'

module WanderWise
  module Representer
    # Represents an opinion for JSON API output
    class Opinion < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia

      property :opinion
    end
  end
end
