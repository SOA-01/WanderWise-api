# frozen_string_literal: true

module Entity
  # Entity for Flights
  class Flight
    attr_reader :id, :origin_location_code, :destination_location_code,
                :departure_date, :price, :airline, :duration,
                :departure_time, :arrival_time

    def initialize(id:, origin_location_code:, destination_location_code:, # rubocop:disable Metrics/ParameterLists
                   departure_date:, price:, airline:, duration:,
                   departure_time:, arrival_time:)
      @id = id
      @origin_location_code = origin_location_code
      @destination_location_code = destination_location_code
      @departure_date = departure_date
      @price = price
      @airline = airline
      @duration = duration
      @departure_time = departure_time
      @arrival_time = arrival_time
    end
  end

  # Entity for Articles
  class Article; end
end
