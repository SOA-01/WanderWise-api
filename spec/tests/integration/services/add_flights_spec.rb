# frozen_string_literal: true

require 'webmock/rspec'
require 'vcr'
require_relative '../../../../app/application/services/add_flights'
require_relative '../../../../app/infrastructure/database/repositories/flights'
require 'dry/monads'
include Dry::Monads[:result]

RSpec.describe WanderWise::Service::AddFlights do
  let(:add_flights_service) { described_class.new }
  let(:flight_data) do
    WanderWise::Flight.new(
      origin_location_code: 'TPE',
      destination_location_code: 'LAX',
      departure_date: (Date.today + 7).to_s,
      adults: 1,
      price: 669.5,
      airline: 'BR',
      duration: 'PT11H40M',
      departure_time: '23:55:00',
      arrival_time: '19:35:00'
    )
  end
  let(:input) { { origin_location_code: 'TPE', destination_location_code: 'LAX', departure_date: (Date.today + 7).to_s, adults: 1 } }

  describe '#find_flights' do
    context 'when flights are found' do
      before do
        puts "Mocking AmadeusAPI to return empty data"  # Debug line
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flights).and_return(flight_data)
      end
    
      it 'returns Failure with an error message when no flights are found' do
        VCR.use_cassette("amadeus_flight_search") do
          result = add_flights_service.send(:find_flights, input)
          puts "Result of find_flights: #{result}"  # Debug line
          expect(result).to be_a(Dry::Monads::Result::Failure)
          expect(result.failure).to eq("Could not find flight data")  # Adjusted to expect symbol as failure message
        end
      end
    end
  
  

    context 'when no flights are found' do
      before do
        puts "Mocking AmadeusAPI to return empty data"  # Debug line
        allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flights).and_return([])
      end

      it 'returns Failure' do
        result = add_flights_service.send(:find_flights, [])
        puts "Result when no flights are found: #{result}"  # Debug line
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not find flight data')
      end
    end
  end

  describe '#store_flights' do
    context 'when storing flights is successful' do
      before do
        puts "Mocking successful flight storage"  # Debug line
        allow(WanderWise::Repository::For.klass(Entity::Flight)).to receive(:create_many).and_return(flight_data)
      end

      it 'returns Success' do
        result = add_flights_service.send(:store_flights, Dry::Monads::Success(flight_data))
        puts "Result of store_flights: #{result}"  # Debug line
        expect(result).to be_a(Dry::Monads::Result::Success)
      end
    end

    context 'when storing flights fails' do
      before do
        puts "Mocking failure in storing flights"  # Debug line
        allow(WanderWise::Repository::For.klass(Entity::Flight)).to receive(:create_many).and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = add_flights_service.send(:store_flights, Dry::Monads::Success(flight_data))
        puts "Result of store_flights when failed: #{result}"  # Debug line
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not save flight data')
      end
    end
  end


  describe '#call' do
    context 'when the transaction fails at find_flights' do
      before do
        VCR.use_cassette('amadeus_oauth_token') do
          allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flight).and_return([])
        end
      end
    
      it 'returns Failure' do
        result = add_flights_service.call([])
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not find flight data')
      end
    end
  

    context 'when the transaction fails at store_flights' do
      before do
        # Wrap the OAuth token request in a VCR cassette
        VCR.use_cassette('amadeus_oauth_token') do
          puts "Mocking find_flight to return: #{flight_data.inspect}"  # Debug log
          allow_any_instance_of(WanderWise::AmadeusAPI).to receive(:find_flight).and_return(flight_data)
        end
        # Simulate failure during storing flights
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:create_many).and_raise(StandardError, 'Database error')
        puts "Simulating database error in create_many"  # Debug log
      end
    
      it 'returns Failure' do
        result = add_flights_service.call(input)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not save flight data')
      end
    end           
  end
end
