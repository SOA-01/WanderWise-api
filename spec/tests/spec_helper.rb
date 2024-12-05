# frozen_string_literal: true

ENV['SESSION_SECRET'] ||= 'T30S7Xh1X1ispHb_Z0Qp7A6pLijJo8esnPjOWcFCIONQNKgdma-DAJ_X9jmSpIIDtV0FndQRZh8lRX80MlAWHg=='
ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.coverage_dir('spec/coverage')
SimpleCov.start
require 'dotenv'
Dotenv.load

require 'yaml'
require 'minitest/autorun'
require 'vcr'
require 'webmock'
require 'rack/test'

require_relative '../../app/application/controllers/app'
require_relative '../../app/infrastructure/amadeus/gateways/amadeus_api'
require_relative '../../app/infrastructure/gemini/gateways/gemini_api'
require_relative '../../app/infrastructure/nytimes/gateways/nytimes_api'
require_relative '../../app/infrastructure/amadeus/mappers/flight_mapper'
require_relative '../../app/infrastructure/nytimes/mappers/article_mapper'
require_relative '../../app/domain/entities/flight'
require_relative '../../app/domain/entities/article'
require_relative 'database_helper'

curr_dir = __dir__
CORRECT_NYT = YAML.load_file("#{curr_dir}/../fixtures/nytimes-results.yml")
CORRECT_FLIGHTS = YAML.load_file("#{curr_dir}/../fixtures/flight-offers-results.yml")

CASSETTES_FOLDER = 'spec/fixtures/cassettes'
CASSETTE_FILE_NYT = 'nyt_api'
CASSETTE_FILE_FLIGHTS = 'flights_api'

VCR.configure do |config|
  config.cassette_library_dir = CASSETTES_FOLDER
  config.hook_into :webmock
  config.filter_sensitive_data('<AMAD_CLIENT_ID>') { ENV['AMADEUS_CLIENT_ID'] }
  config.filter_sensitive_data('<NYT_API_KEY>') { ENV['NYTIMES_API_KEY'] }
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end
