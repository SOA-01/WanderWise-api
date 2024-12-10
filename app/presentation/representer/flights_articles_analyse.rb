# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'article_list'
require_relative 'flights_list'
require_relative 'misc_data'

module WanderWise
  module Representer
    class FlightsArticlesAnalyse < Roar::Decorator
      include Roar::JSON

      property :misc_data, extend: Representer::MiscData, class: OpenStruct
      property :flights, extend: Representer::FlightsRepresenter, class: OpenStruct
      property :articles, extend: Representer::ArticlesRepresenter, class: OpenStruct
    end
  end
end
