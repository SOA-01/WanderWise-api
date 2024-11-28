# frozen_string_literal: true

require 'rspec'
require 'yaml'
require 'simplecov'
SimpleCov.start

require_relative 'spec_helper'
require_relative '../../app/infrastructure/database/repositories/for'
require_relative '../../app/infrastructure/database/repositories/flights'
require_relative '../../app/infrastructure/database/repositories/articles'
require_relative '../../app/infrastructure/database/repositories/entity'

# RSpec.describe WanderWise::AmadeusAPI do
#   VCR.configure do |c|
#     c.cassette_library_dir = 'spec/fixtures/cassettes'
#     c.hook_into :webmock
#   end

#   before do
#     VCR.insert_cassette 'amadeus-results', record: :new_episodes, match_requests_on: %i[method uri body]
#   end

#   after do
#     VCR.eject_cassette
#   end

#   let(:amadeus_api) { WanderWise::AmadeusAPI.new }

#   # Get path through expanding the current directory
#   __dir__
#   let(:fixture_flight) { YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures', 'amadeus-results.yml')) }
#   date_next_week = (Date.today + 7).to_s
#   params = { 'originLocationCode' => 'TPE', 'destinationLocationCode' => 'LAX', 'departureDate' => date_next_week, 'adults' => '1' }

#   describe '#api call to Amadeus', :vcr do
#     it 'receives valid JSON response from the API' do
#       flight_offers = amadeus_api.fetch_response(params)

#       # Assert that there are flight offers
#       expect(flight_offers['data']).not_to be_empty, 'No flight offers available for the given parameters'

#       # Proceed with the test if flight offers are present
#       api_offer = flight_offers['data'].first
#       fixture_offer = fixture_flight['data'].first

#       # Check that the first key in the response matches with the fixture (we'll check 'id' and 'source' as an example)
#       expect(api_offer['id']).to eq(fixture_offer['id'])
#       expect(api_offer['source']).to eq(fixture_offer['source'])

#       # Check the first itinerary segment (departure and arrival)
#       itinerary = api_offer['itineraries'].first
#       fixture_itinerary = fixture_offer['itineraries'].first

#       expect(itinerary['duration']).to eq(fixture_itinerary['duration'])

#       segment = itinerary['segments'].first
#       fixture_segment = fixture_itinerary['segments'].first

#       expect(segment['departure']['iataCode']).to eq(fixture_segment['departure']['iataCode'])
#       expect(segment['arrival']['iataCode']).to eq(fixture_segment['arrival']['iataCode'])
#     end
#   end
# end

# RSpec.describe WanderWise::NYTimesAPI do
#   VCR.configure do |c|
#     c.cassette_library_dir = 'spec/fixtures/cassettes'
#     c.hook_into :webmock
#   end

#   before do
#     VCR.insert_cassette 'nytimes-api-results', record: :new_episodes, match_requests_on: %i[method uri body]
#   end

#   after do
#     VCR.eject_cassette
#   end

#   let(:nytimes_api) { WanderWise::NYTimesAPI.new }

#   curr_dir = __dir__
#   let(:fixture_articles) { YAML.load_file("#{curr_dir}/fixtures/nytimes-api-results.yml") }

#   describe '#articles', :vcr do
#     it 'gets valid JSON with articles' do
#       api_articles = nytimes_api.fetch_recent_articles('China')
#       expect(api_articles).not_to be_empty

#       api_example = api_articles['response']['docs'].first
#       fixture_example = fixture_articles['response']['docs'].first

#       # Adjust the expected keys to match the actual response structure
#       expect(api_example.keys[0..4]).to eq(fixture_example.keys[0..4])
#     end
#   end
# end

RSpec.describe WanderWise::GeminiAPI, :vcr do
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/cassettes'
    c.hook_into :webmock
  end

  before do
    VCR.insert_cassette 'gemini-api-results', record: :new_episodes, match_requests_on: %i[method uri body]
  end

  after do
    VCR.eject_cassette
  end

  let(:gemini_api) { WanderWise::GeminiAPI.new }

  it 'receives valid response from the API' do
    prompt = 'Tell me about China in 10-15 words'
    response = gemini_api.gemini_api_call(prompt)
    # binding.irb

    expect(response).not_to be_empty
  end
end
