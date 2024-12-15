# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'
require 'roar/hypermedia'

module WanderWise
  module Representer
    # Represents an article for JSON API output
    class Article < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia

      property :title
      property :published_date
      property :url
    end
  end
end
