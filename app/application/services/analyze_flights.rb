# frozen_string_literal: true

require 'dry/transaction'
require 'logger'

module WanderWise
  module Service
    # Service to analyze flight data
    class AnalyzeFlights
      include Dry::Transaction

      step :analyze_flights

      private

      def analyze_flights(input)
        historical_average_data = historical_average(input)
        historical_lowest_data = historical_lowest(input)

        if historical_average_data.failure? || historical_lowest_data.failure?
          logger.error("Failed to analyze flight data: #{historical_average_data.failure} / #{historical_lowest_data.failure}")
          return Failure('Could not analyze flight data')
        end

        Success(
          historical_average_data: historical_average_data.value!,
          historical_lowest_data: historical_lowest_data.value!
        )
      rescue StandardError => e
        logger.error("Error analyzing flights: #{e.message}")
        Failure('Could not analyze flight data')
      end

      def historical_average(input)
        average_price = Repository::For.klass(Entity::Flight).find_average_price_from_to(
          input.first.origin_location_code,
          input.first.destination_location_code
        ).round(2)

        if average_price.nil? || average_price <= 0
          logger.error("Historical average price not found or invalid for: #{input}")
          return Failure('Could not retrieve historical average data')
        end

        Success(average_price)
      rescue StandardError => e
        logger.error("Error retrieving historical average data: #{e.message}")
        Failure('Could not retrieve historical average data')
      end

      def historical_lowest(input)
        lowest_price = Repository::For.klass(Entity::Flight).find_best_price_from_to(
          input.first.origin_location_code,
          input.first.destination_location_code
        )

        if lowest_price.nil? || lowest_price <= 0
          logger.error("Historical lowest price not found or invalid for: #{input}")
          return Failure('Could not retrieve historical lowest data')
        end

        Success(lowest_price)
      rescue StandardError => e
        logger.error("Error retrieving historical lowest data: #{e.message}")
        Failure('Could not retrieve historical lowest data')
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
