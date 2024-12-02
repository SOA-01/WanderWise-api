# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module WanderWise
  module Representer
    # Represents an article for JSON API output
    class ArticleRepresenter < Roar::Decorator
      include Roar::JSON

      property :title
      property :published_date
      property :url
    end
  end
end
