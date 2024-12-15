# frozen_string_literal: true

require 'dry/transaction'
require 'redis'
require_relative '../../infrastructure/database/repositories/flights'
require 'logger'

module WanderWise
  module Service
    # Service to store flight data
    class AddFlights # rubocop:disable Metrics/ClassLength
      include Dry::Transaction

      step :validate_input
      step :find_flights
      step :store_flights

      def validate_input(input)
        required_keys = %w[originLocationCode destinationLocationCode departureDate adults]
        missing_keys = required_keys.select { |key| input[key].nil? }

        if missing_keys.any?
          logger.error("Missing mandatory parameters: #{missing_keys.join(', ')}")
          return Failure("Missing mandatory parameters: #{missing_keys.join(', ')}")
        end

        Success(input)
      rescue StandardError => e
        logger.error("Error validating input: #{e.message}")
        Failure('Could not validate input')
      end

      def find_flights(input) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        result = flights_from_cache_or_amadeus(input)

        if result.failure?
          logger.error("Failed to find flights: #{result.failure}")
          return result
        end

        # Ensure we pass an array of Flight entities
        flights = result.value!
        unless flights.all? { |flight| flight.is_a?(WanderWise::Flight) }
          logger.error("Invalid flight data structure: #{flights.inspect}")
          return Failure('Invalid flight data')
        end

        Success(flights)
      rescue StandardError => e
        logger.error("Error finding flights: #{e.message}")
        Failure('Could not find flight data')
      end

      def store_flights(input) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # Transform WanderWise::Flight objects into Entity::Flight if needed
        input = input.map do |flight|
          if flight.is_a?(WanderWise::Flight)
            Entity::Flight.new(
              id: flight.id,
              origin_location_code: flight.origin_location_code,
              destination_location_code: flight.destination_location_code,
              departure_date: flight.departure_date,
              price: flight.price,
              airline: flight.airline,
              duration: flight.duration,
              departure_time: flight.departure_time,
              arrival_time: flight.arrival_time
            )
          else
            flight
          end
        end

        unless input.all? { |flight| flight.is_a?(Entity::Flight) }
          logger.error("Expected array of Entity::Flight, got: #{input.inspect}")
          return Failure('Invalid input for storing flights')
        end

        Repository::For.klass(Entity::Flight).create_many(input)
        logger.debug('Successfully stored flight data')
        Success(input)
      rescue StandardError => e
        logger.error("Error saving flights: #{e.message}")
        Failure('Could not save flight data')
      end

      def flights_from_cache_or_amadeus(input) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        cache_key = cache_key_for(input)

        # Check if data is already in the cache
        cached_data = redis.get(cache_key)
        if cached_data
          logger.debug("Returning cached flight data for key: #{cache_key}")
          flights = JSON.parse(cached_data, symbolize_names: true).map do |flight_data|
            WanderWise::Flight.new(flight_data)
          end
          return Success(flights)
        end

        # If not in cache, send request to queue to trigger the worker
        fetch_flights_from_amadeus(input)

        # Wait for the worker to populate the cache
        max_wait_time = 60 # Maximum wait time in seconds
        interval = 1 # Interval in seconds to check cache
        elapsed_time = 0

        while elapsed_time < max_wait_time
          cached_data = redis.get(cache_key)
          if cached_data
            logger.debug("Returning cached flight data for key: #{cache_key}")
            flights = JSON.parse(cached_data, symbolize_names: true).map do |flight_data|
              WanderWise::Flight.new(flight_data)
            end
            return Success(flights)
          end

          # Wait before checking again
          sleep(interval)
          elapsed_time += interval
        end

        logger.error("Timeout waiting for flight data in cache: #{cache_key}")
        Failure('Timeout waiting for flight data')
      end

      private

      def fetch_flights_from_amadeus(input)
        response = Messaging::Queue.new(App.config.WANDERWISE_QUEUE_URL, App.config)
                                   .send(input)

        if response.empty?
          logger.error("Failed to fetch flight data: #{response.failure}")
          return Failure('Failed to fetch flight data')
        end

        logger.debug('Flight data retrieved')
        Success(response)
      end

      def cache_key_for(input)
        "flights:#{input['originLocationCode']}:#{input['destinationLocationCode']}:#{input['departureDate']}:#{input['adults']}"
      end

      def cache_ttl
        3600 # Cache duration in seconds (1 hour)
      end

      def redis
        @redis ||= Redis.new(url: App.config.REDIS_URL)
      rescue StandardError => e
        logger.error("Redis connection error: #{e.message}")
        raise e
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
