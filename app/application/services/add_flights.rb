# frozen_string_literal: true

require 'dry/transaction'
require_relative '../../infrastructure/database/repositories/flights'
require 'logger'

module WanderWise
  module Service
    # Service to store flight data
    class AddFlights
      include Dry::Transaction

      step :find_flights
      step :store_flights

      private

      def find_flights(input)
        required_keys = [:origin_location_code, :destination_location_code, :departure_date, :adults]
        missing_keys = required_keys.select { |key| input[key].nil? }
      
        if missing_keys.any?
          logger.error("Missing mandatory parameters: #{missing_keys.join(', ')}")
          return Failure("Missing mandatory parameters: #{missing_keys.join(', ')}")
        end
      
        result = flights_from_amadeus(input)
        puts "Result of find_flights: #{result.inspect}"
      
        if result.failure?
          # Log the failure details
          logger.error("Failed to find flights: #{result.failure}")
          return result
        end
      
        logger.debug("Flight data found: #{result.value!}")
        Success(result.value!)
      rescue StandardError => e
        logger.error("Error finding flights: #{e.message}")
        Failure('Could not find flight data')
      end
      

      def store_flights(input)
        logger.debug("Storing flight data: #{input}")
      
        Repository::For.klass(Entity::Flight).create_many(input)
      
        logger.debug("Successfully stored flight data: #{input}")
        Success(input)
      rescue StandardError => e
        logger.error("Error saving flights: #{e.message}")
        Failure('Could not save flight data')
      end
      

      def flights_from_amadeus(input)
        amadeus_api = AmadeusAPI.new
        flight_mapper = FlightMapper.new(amadeus_api)
      
        logger.debug("Requesting flights from Amadeus with input: #{input}")
        flight_data = flight_mapper.find_flight(input)
      
        if flight_data.empty? || flight_data.nil?
          logger.error("No flights found for the given criteria: #{input}")
          return Failure('No flights found for the given criteria.')
        end
      
        logger.debug("Flight data retrieved: #{flight_data}")
        Success(flight_data)
      end
      

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
