# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require 'rspec'
require_relative 'spec_helper'
require 'vcr'

RSpec.describe WanderWise::FlightMapper do # rubocop:disable Metrics/BlockLength
  VCR.configure do |c|
    c.cassette_library_dir = CASSETTES_FOLDER
    c.hook_into :webmock
  end

  before do
    VCR.insert_cassette CASSETTE_FILE_FLIGHTS,
                        record: :new_episodes,
                        match_requests_on: %i[method uri body]
  end

  after do
    VCR.eject_cassette
  end

  let(:gateway) { WanderWise::AmadeusAPI.new }
  let(:mapper) { WanderWise::FlightMapper.new(gateway) }

  let(:fixture_flight) { YAML.load_file(File.expand_path('../fixtures/amadeus-results.yml', __dir__)) }

  describe '#find_flight' do
    it 'transforms API response into FlightsEntity object' do
      # Load data from the fixture and structure it to match the API response format
      fixture_data = { 'data' => fixture_flight['data'] }
      allow(gateway).to receive(:fetch_response).and_return(fixture_data)

      date_next_week = (Date.today + 7).to_s
      params = { originLocationCode: 'TPE', destinationLocationCode: 'LAX', departureDate: date_next_week, adults: 1 }

      flight = mapper.find_flight(params).first

      expect(flight).to be_a(WanderWise::Flight)
      expect(flight.origin_location_code).to eq(fixture_data['data'].first.dig('itineraries', 0, 'segments', 0, 'departure', 'iataCode'))
      expect(flight.destination_location_code).to eq(fixture_data['data'].first.dig('itineraries', 0, 'segments', -1, 'arrival', 'iataCode'))
    end
  end
end

RSpec.describe WanderWise::ArticleMapper do
  VCR.configure do |c|
    c.cassette_library_dir = CASSETTES_FOLDER
    c.hook_into :webmock
  end

  before do
    VCR.insert_cassette "nyt_api_#{Time.now.to_i}", record: :new_episodes, match_requests_on: %i[method uri body]
  end

  after do
    VCR.eject_cassette
  end

  let(:gateway) { WanderWise::NYTimesAPI.new }
  let(:mapper) { WanderWise::ArticleMapper.new(gateway) }

  let(:fixture_flight) { YAML.load_file(File.expand_path('fixtures/amadeus-results.yml', __dir__)) }

  describe '#find_articles' do
    it 'transforms API response into an array of ArticleEntity objects' do
      articles = mapper.find_articles('Taiwan')

      expect(articles).to be_an(Array)
      expect(articles.first).to be_a(WanderWise::Article)
      # expect(articles.first.title).to eq(fixture_articles.first.dig('headline', 'main'))
      # expect(articles.first.published_date).to eq(fixture_articles.first['pub_date'])
      # expect(articles.first.url).to eq(fixture_articles.first['web_url'])
    end
  end
end
