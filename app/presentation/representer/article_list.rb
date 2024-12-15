# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'article'

module WanderWise
  module Representer
    # Represents a collection of articles for JSON API output
    class Articles < Roar::Decorator
      include Roar::JSON

      collection :articles, extend: Representer::Article, class: OpenStruct
    end
  end
end
