# frozen_string_literal: true

require 'webmock/rspec'
require 'vcr'
require_relative '../../../../app/application/services/add_flights'
require_relative '../../../../app/infrastructure/database/repositories/flights'

RSpec.describe WanderWise::Service::AddFlights do # rubocop:disable Metrics/BlockLength
  include Rack::Test::Methods

  date_next_week = (Date.today + 7).to_s

  let(:add_flights_service) { described_class.new }
  let(:flight_data) do
    WanderWise::Flight.new(
      origin_location_code: 'TPE',
      destination_location_code: 'LAX',
      departure_date: date_next_week,
      price: 669.5,
      airline: 'BR',
      duration: 'PT11H40M',
      departure_time: '23:55:00',
      arrival_time: '19:35:00'
    )
  end
  let(:input) { { originLocationCode: 'TPE', destinationLocationCode: 'LAX', departureDate: date_next_week, adults: 1 } }

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/cassettes'
    c.hook_into :webmock
  end

  before do
    VCR.insert_cassette 'amadeus-results', record: :new_episodes, match_requests_on: %i[method uri body]
  end

  after do
    VCR.eject_cassette
  end

  describe '#find_flights' do # rubocop:disable Metrics/BlockLength
    context 'when flights are found' do
      before do
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flights).and_return(flight_data)
        allow_any_instance_of(WanderWise::Service::AddFlights).to receive(:Success).and_call_original
      end

      it 'returns Success with flight data' do
        result = add_flights_service.send(:find_flights, input)
        expect(result).to be_a(Dry::Monads::Result::Success)

        result_flight = result.value!.first
        expect(result_flight.origin_location_code).to eq(flight_data.origin_location_code)
        expect(result_flight.destination_location_code).to eq(flight_data.destination_location_code)
        expect(result_flight.departure_date).to eq(flight_data.departure_date)
        expect(result_flight.price).to eq(flight_data.price)
        expect(result_flight.airline).to eq(flight_data.airline)
        expect(result_flight.duration).to eq(flight_data.duration)
      end
    end

    context 'when no flights are found' do
      before do
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flights).and_return([])
      end

      it 'returns Failure' do
        result = add_flights_service.send(:find_flights, [])
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not find flight data')
      end
    end
  end

  describe '#store_flights' do
    context 'when storing flights is successful' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:create_many).and_return(flight_data)
      end

      it 'returns Success' do
        result = add_flights_service.send(:store_flights, Dry::Monads::Success(flight_data))
        expect(result).to be_a(Dry::Monads::Result::Success)
      end
    end

    context 'when storing flights fails' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:create_many).and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = add_flights_service.send(:store_flights, Dry::Monads::Success(flight_data))
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not save flight data')
      end
    end
  end

  describe '#call' do
    context 'when the transaction fails at find_flights' do
      before do
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flight).and_return([])
      end

      it 'returns Failure' do
        result = add_flights_service.call([])
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not find flight data')
      end
    end

    context 'when the transaction fails at store_flights' do
      before do
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flight).and_return(flight_data)
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:create_many).and_raise(StandardError, 'Database error')
      end

      it 'returns Failure' do
        result = add_flights_service.call(input)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not save flight data')
      end
    end
  end
end
