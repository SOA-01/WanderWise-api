# frozen_string_literal: true

require 'roda'
require 'rack'
require 'slim'
require 'figaro'
require 'securerandom'
require 'logger'
require 'json'
require 'timeout'

require_relative '../../presentation/representer/http_response'
require_relative '../../presentation/responses/api_result'
require_relative '../requests/new_flight'
require_relative '../services/add_flights'
require_relative '../services/find_articles'

module WanderWise
  # Main application class for WanderWise
  class App < Roda # rubocop:disable Metrics/ClassLength
    plugin :flash
    plugin :halt
    plugin :all_verbs
    plugin :sessions, secret: ENV['SESSION_SECRET']

    def logger
      @logger ||= Logger.new($stdout)
    end

    route do |routing| # rubocop:disable Metrics/BlockLength
      # Example session endpoints remain unchanged
      routing.get 'set_session' do
        session[:watching] = 'Some value'
        'Session data set!'
      end

      routing.get 'show_session' do
        session_data = session[:watching] || 'No data in session'
        "Session data: #{session_data}"
      end

      # Root endpoint
      routing.root do
        message = 'WanderWise API v1 at /api/v1/ in development mode'
        result_response = WanderWise::Representer::HttpResponse.new(
          WanderWise::Response::ApiResult.new(status: :ok, message:)
        )

        response.status = result_response.http_status_code
        result_response.to_json
      end

      # API v1 routes
      routing.on 'api', 'v1' do # rubocop:disable Metrics/BlockLength
        # POST /api/v1/flights?origin_location_code=...&destination_location_code=...&departure_date=...&adults=...
        routing.on 'flights' do
          routing.post do
            # Extract parameters directly from the query string
            params = routing.params
            logger.info "Received flight query: #{params}"

            # Validate and process the flight request
            request = WanderWise::Requests::NewFlightRequest.new(params).call
            if request.failure?
              response.status = 400
              return { error: request.failure }.to_json
            end

            flight_made = Service::AddFlights.new.find_flights(request.value!)
            if flight_made.failure?
              failed_response = Representer::HttpResponse.new(
                WanderWise::Response::ApiResult.new(status: :internal_error, message: flight_made.failure)
              )
              routing.halt failed_response.http_status_code, failed_response.to_json
            end

            # Store the flights if needed
            Service::AddFlights.new.store_flights(flight_made.value!)

            # Return the flight data
            flight_data = flight_made.value!

            representable_data = OpenStruct.new(flights: flight_data)
            Representer::Flights.new(representable_data).to_json
          rescue StandardError => e
            logger.error "Flight endpoint error: #{e.message}"
            response.status = 500
            { error: 'An unexpected error occurred while processing flights' }.to_json
          end
        end

        # POST /api/v1/article?country=spain
        routing.on 'articles' do
          routing.post do
            country = routing.params['country']
            logger.info "Received article query for country: #{country}"

            if country.nil? || country.strip.empty?
              response.status = 400
              return { error: 'Country parameter is required' }.to_json
            end

            article_made = Service::FindArticles.new.call(country)
            if article_made.failure?
              failed_response = Representer::HttpResponse.new(
                WanderWise::Response::ApiResult.new(status: :internal_error, message: article_made.failure)
              )
              routing.halt failed_response.http_status_code, failed_response.to_json
            end

            nytimes_articles = article_made.value!

            representable_data = OpenStruct.new(articles: nytimes_articles)
            Representer::Articles.new(representable_data).to_json
          rescue StandardError => e
            logger.error "Article endpoint error: #{e.message}"
            response.status = 500
            { error: 'An unexpected error occurred while fetching articles' }.to_json
          end
        end

        routing.on 'analyze' do # rubocop:disable Metrics/BlockLength
          routing.post do # rubocop:disable Metrics/BlockLength
            logger.info "Analyse request params: #{routing.params.inspect}"
            request = WanderWise::Requests::NewFlightRequest.new(routing.params).call

            if request.failure?
              failed_response = Representer::HttpResponse.new(
                WanderWise::Response::ApiResult.new(status: :bad_request, message: request.failure)
              )
              routing.halt failed_response.http_status_code, failed_response.to_json
            end

            flight_data = routing.params

            # Analyze the retrieved flights
            flights_analysis = Service::AnalyzeFlights.new.call(flight_data)
            if flights_analysis.failure?
              failed_response = Representer::HttpResponse.new(
                WanderWise::Response::ApiResult.new(status: :internal_error, message: flights_analysis.failure)
              )
              routing.halt failed_response.http_status_code, failed_response.to_json
            end

            analysis_data = {
              historical_average_data: flights_analysis.value![:historical_average_data],
              historical_lowest_data: flights_analysis.value![:historical_lowest_data]
            }

            response.status = 200
            analysis_data.to_json
          rescue StandardError => e
            logger.error "Error analysing flights: #{e.message}"
            response.status = 500
            { error: 'Internal Server Error' }.to_json
          end
        end

        routing.on 'opinion' do # rubocop:disable Metrics/BlockLength
          routing.get do # rubocop:disable Metrics/BlockLength
            logger.info 'Received opinion request'

            params = routing.params

            if params.nil? || params.empty?
              response.status = 400
              return { error: 'No parameters provided' }.to_json
            end

            begin
              opinion_data = Timeout.timeout(10) do
                opinion_made = Service::GetOpinion.new.call(params)

                if opinion_made.failure?
                  failed_response = Representer::HttpResponse.new(
                    WanderWise::Response::ApiResult.new(status: :internal_error, message: opinion_made.failure)
                  )
                  routing.halt failed_response.http_status_code, failed_response.to_json
                end

                opinion_made.value!
              end

              representable_data = OpenStruct.new(opinion: opinion_data)
              Representer::Opinion.new(representable_data).to_json
            rescue Timeout::Error
              logger.error 'Opinion request timed out'
              response.status = 200
              { opinion: 'No opinion available' }.to_json
            rescue StandardError => e
              logger.error "Error getting opinion: #{e.message}"
              response.status = 500
              { error: 'Internal Server Error' }.to_json
            end
          end
        end
      end
    end
  end
end
