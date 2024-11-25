# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../../../../app/application/services/analyze_flights'
require_relative '../../../../app/infrastructure/database/repositories/flights'

RSpec.describe WanderWise::Service::AnalyzeFlights do # rubocop:disable Metrics/BlockLength
  let(:analyze_flights_service) { described_class.new }
  let(:input) do
    [WanderWise::Flight.new(
      origin_location_code: 'TPE',
      destination_location_code: 'LAX',
      departure_date: (Date.today + 7).to_s,
      price: 669.5,
      airline: 'BR',
      duration: 'PT11H40M',
      departure_time: '23:55:00',
      arrival_time: '19:35:00'
    )]
  end
  let(:average_price) { 700.0 }
  let(:lowest_price) { 600.0 }

  describe '#analyze_flights' do # rubocop:disable Metrics/BlockLength
    context 'when analysis is successful' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_average_price_from_to)
          .and_return(average_price)

        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_best_price_from_to)
          .and_return(lowest_price)
      end

      it 'returns Success with analyzed data' do
        result = analyze_flights_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value![:historical_average_data]).to eq(average_price.round(2))
        expect(result.value![:historical_lowest_data]).to eq(lowest_price)
      end
    end

    context 'when retrieving historical average data fails' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_average_price_from_to)
          .and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = analyze_flights_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not analyze flight data')
      end
    end

    context 'when retrieving historical lowest data fails' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_average_price_from_to)
          .and_return(average_price)

        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_best_price_from_to)
          .and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = analyze_flights_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not analyze flight data')
      end
    end
  end

  describe '#historical_average' do
    context 'when data retrieval is successful' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_average_price_from_to)
          .and_return(average_price)
      end

      it 'returns Success with average price' do
        result = analyze_flights_service.send(:historical_average, input)

        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(average_price.round(2))
      end
    end

    context 'when data retrieval fails' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_average_price_from_to)
          .and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = analyze_flights_service.send(:historical_average, input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not retrieve historical average data')
      end
    end
  end

  describe '#historical_lowest' do
    context 'when data retrieval is successful' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_best_price_from_to)
          .and_return(lowest_price)
      end

      it 'returns Success with lowest price' do
        result = analyze_flights_service.send(:historical_lowest, input)

        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(lowest_price)
      end
    end

    context 'when data retrieval fails' do
      before do
        allow(WanderWise::Repository::For.klass(Entity::Flight))
          .to receive(:find_best_price_from_to)
          .and_raise(StandardError, 'Database error')
      end

      it 'returns Failure with an error message' do
        result = analyze_flights_service.send(:historical_lowest, input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('Could not retrieve historical lowest data')
      end
    end
  end
end
