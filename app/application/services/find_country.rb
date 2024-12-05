# frozen_string_literal: true

require 'dry/transaction'
require 'logger'
require 'airports'

module WanderWise
  module Service
    # Service to find a country
    class FindCountry
      include Dry::Transaction

      step :find_country

      private

      def find_country(input)
        country = Airports.find_by_iata_code(input.first.destination_location_code)&.country

        if country.nil?
          logger.error("Country not found for IATA code: #{input.first.destination_location_code}")
          return Failure('Unable to find country for the destination location code.')
        end

        Success(country)
      rescue StandardError => e
        logger.error("Error finding country: #{e.message}")
        Failure('Unable to find country for the destination location code.')
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
