# frozen_string_literal: true

require 'roda'
require 'rack'
require 'slim'
require 'figaro'
require 'securerandom'
require 'logger'

require_relative '../../presentation/representer/http_response'
require_relative '../../presentation/responses/api_result'
require_relative '../requests/new_flight'

module WanderWise
  # Main application class for WanderWise
  class App < Roda
    plugin :flash
    plugin :halt
    plugin :all_verbs
    plugin :sessions, secret: ENV['SESSION_SECRET']

    # Create a logger instance (you can change the log file path as needed)
    def logger
      @logger ||= Logger.new($stdout) # Logs to standard output (console)
    end

    route do |routing| # rubocop:disable Metrics/BlockLength
      # Example of setting session data
      routing.get 'set_session' do
        session[:watching] = 'Some value'
        'Session data set!'
      end

      # Example of accessing session data
      routing.get 'show_session' do
        session_data = session[:watching] || 'No data in session'
        "Session data: #{session_data}"
      end

      # GET / request
      routing.root do
        # Get cookie viewers from session
        # session[:watching] ||= []
        message = 'WanderWise API v1 at /api/v1/ in development mode'
        result_response = WanderWise::Representer::HttpResponse.new(
          WanderWise::Response::ApiResult.new(status: :ok, message:)
        )

        response.status = result_response.http_status_code
        result_response.to_json
      end

      # POST /submit - Handle submitting flight data
      routing.post 'submit' do # rubocop:disable Metrics/BlockLength
        # Step 0: Validate form data

        request = WanderWise::Requests::NewFlightRequest.new(routing.params).call
        if request.failure?
          session[:flash] = { error: request.failure.message }
          routing.redirect '/'
        end

        flight_made = Service::AddFlights.new.call(request.to_h)

        if flight_made.failure?
          failed = Representer::HttpResponse.new(result.failure)
          routing.halt failed.http_status_code, failed.to_json
        end

        http_response = Representer::HttpResponse.new(result.value!)
        response.status = http_response.http_status_code
        Representer::Project.new(result.value!.message).to_json

        flight_data = flight_made.value!

        country = Service::FindCountry.new.call(flight_data)

        if country.failure?
          session[:flash] = { error: country.failure }
          routing.redirect '/'
        end

        country = country.value!

        # Step 4: Retrieve historical flight price data
        analyze_flights = Service::AnalyzeFlights.new.call(flight_data)

        if analyze_flights.failure?
          session[]
          routing.redirect '/'
        end

        article_made = Service::FindArticles.new.call(country)

        if article_made.failure?
          session[:flash] = { error: article_made.failure }
          routing.redirect '/'
        end

        nytimes_articles = article_made.value!

        retrieved_flights = Views::FlightList.new(flight_data)
        retrieved_articles = Views::ArticleList.new(nytimes_articles)
        historical_flight_data = Views::HistoricalFlightData.new(analyze_flights.value![:historical_average_data],
                                                                 analyze_flights.value![:historical_lowest_data])
        destination_country = Views::Country.new(country)

        # TODO: - REFACTOR GEMINI API CALL

        # Step 6: Ask AI for opinion on the destination
        gemini_api = WanderWise::GeminiAPI.new
        gemini_mapper = WanderWise::GeminiMapper.new(gemini_api)

        month = routing.params['departureDate'].split('-')[1].to_i
        destination = routing.params['destinationLocationCode']
        origin = routing.params['originLocationCode']
        gemini_answer = gemini_mapper.find_gemini_data("What is your opinion on #{destination} in #{month}?" + "Based on historical data, the average price for a flight from #{origin} to #{destination} is $#{historical_flight_data.historical_average_data}. Does it seem safe based on recent news articles: #{nytimes_articles}?") # rubocop:disable Layout/LineLength

        # Render the results view with all gathered data
        view 'results', locals: {
          flight_data: retrieved_flights, country: destination_country, nytimes_articles: retrieved_articles,
          gemini_answer:, historical_data: historical_flight_data
        }
      rescue StandardError => e
        flash[:error] = 'An unexpected error occurred'
        logger.error "Flash Error: #{flash[:error]} - #{e.message}"
        session[:flash] = flash.to_hash
        routing.redirect '/' # Do not redirect immediately after setting flash
      end
    end
  end
end
