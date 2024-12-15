# frozen_string_literal: true

require_relative '../require_app'
require_app

require 'shoryuken'
require 'logger'
require 'redis'

# Worker to find flights
class FindFlightsWorker
  include Shoryuken::Worker

  shoryuken_options queue: Figaro.env.WANDERWISE_QUEUE_URL, auto_delete: true

  def perform(_sqs_msg, request) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    logger.info "Processing request: #{request}"
    request = JSON.parse(request) if request.is_a?(String)

    cache_key = generate_cache_key(request)

    if redis.get(cache_key)
      logger.info "Results already cached for request: #{request}"
      return
    end

    amadeus_api = WanderWise::AmadeusAPI.new
    flight_mapper = WanderWise::FlightMapper.new(amadeus_api)

    flights = flight_mapper.find_flight(request)

    if flights.any? # Check if the array has elements
      serialized_data = flights.map(&:to_h).to_json
      redis.set(cache_key, serialized_data, ex: cache_expiry_time)
      logger.info "Successfully cached results for request: #{request}"
    else
      logger.error "No flights found for request: #{request}"
    end
  rescue StandardError => e
    logger.error "Error processing request: #{request} - #{e.message}"
    raise e
  end

  private

  # Redis client
  def redis
    @redis ||= Redis.new(url: Figaro.env.REDIS_URL) # Ensure REDIS_URL is set in your environment
  end

  # Generate a unique cache key based on the request parameters
  def generate_cache_key(request)
    "flights:#{request['originLocationCode']}:#{request['destinationLocationCode']}:#{request['departureDate']}:#{request['adults']}"
  end

  # Cache expiry time in seconds (e.g., 1 hour)
  def cache_expiry_time
    60
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
