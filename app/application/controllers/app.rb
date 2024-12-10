# frozen_string_literal: true

require 'roda'
require 'rack'
require 'slim'
require 'figaro'
require 'securerandom'
require 'logger'
require 'json'

require_relative '../../presentation/representer/http_response'
require_relative '../../presentation/responses/api_result'
require_relative '../requests/new_flight'
require_relative '../services/add_flights'
require_relative '../services/find_country'
require_relative '../services/analyze_flights'
require_relative '../services/find_articles'

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
      routing.on 'api/v1' do
        # Step 0: Validate form data
        routing.on 'submit' do
          routing.post do
            # Step 1: Add flight data
            logger.info "Raw body: #{routing.body.read}"

            logger.debug 'Parsing body'
            # Rewind the body so it can be read again
            routing.body.rewind

            # Attempt to parse the body
            begin
              parsed_body = JSON.parse(routing.body.read)
              logger.info "Parsed body: #{parsed_body.inspect}"
              routing.params.merge!(parsed_body) # Merge parsed data into routing.params
            rescue JSON::ParserError => e
              logger.error "JSON parse error: #{e.message}"
              response.status = 400
              return { error: "Invalid JSON format: #{e.message}" }.to_json
            end

            logger.debug "Parsed body: #{parsed_body}"
            request = WanderWise::Requests::NewFlightRequest.new(parsed_body).call
            # logger.debug "Request: #{request}"
            flight_made = Service::AddFlights.new.find_flights(request.value!)
            Service::AddFlights.new.store_flights(flight_made.value!)

            if flight_made.failure?
              failed_response = Representer::HttpResponse.new(
                WanderWise::Response::ApiResult.new(status: :internal_error, message: flight_made.failure)
              )
              routing.halt failed_response.http_status_code, failed_response.to_json
            end

            flight_data = flight_made.value!

            # Step 2: Retrieve country data
            country = Service::FindCountry.new.call(flight_data)
            if country.failure?
              session[:flash] = { error: country.failure }
              routing.redirect '/'
            end
            country_data = country.value!

            # Step 3: Analyze historical flight data
            flights_analysis = Service::AnalyzeFlights.new.call(flight_data)
            if flights_analysis.failure?
              session[:flash] = { error: flights_analysis.failure }
              routing.redirect '/'
            end

            # Step 4: Retrieve articles
            article_made = Service::FindArticles.new.call(country_data)
            if article_made.failure?
              session[:flash] = { error: article_made.failure }
              routing.redirect '/'
            end
            nytimes_articles = article_made.value!

            # Step 5: Prepare data for the view -- DEBUG from here
            logger.info 'Preparing data for view'
            retrieved_flights = Representer::FlightsRepresenter.new(flight_data)
            retrieved_articles = Representer::ArticlesRepresenter.new(nytimes_articles)
            misc_data = Representer::MiscData.new(
              [flights_analysis.value![:historical_average_data],
               flights_analysis.value![:historical_lowest_data], country_data]
            )

            # logger.info 'AI calls'
            # # Step 6: Ask AI for opinion on the destination
            # gemini_api = WanderWise::GeminiAPI.new
            # gemini_mapper = WanderWise::GeminiMapper.new(gemini_api)

            # month = routing.params['departureDate'].split('-')[1].to_i
            # destination = routing.params['destinationLocationCode']
            # origin = routing.params['originLocationCode']

            # logger.info 'Calling Gemini API'
            # gemini_answer = gemini_mapper.find_gemini_data(
            #   "What is your opinion on #{destination} in #{month}?" \
            #   "Based on historical data, the average price for a flight from #{origin} to #{destination} is $#{flights_analysis.value![:historical_average_data]}." \
            #   "Does it seem safe based on recent news articles: #{nytimes_articles}?"
            # )

            # Render the result representation
            logger.info 'Rendering results'
            Representer::FlightsArticlesAnalyse.new(
              misc_data: misc_data,
              flights: retrieved_flights,
              articles: retrieved_articles
            ).to_json
          rescue StandardError => e
            flash[:error] = 'An unexpected error occurred'
            logger.error "Flash Error: #{flash[:error]} - #{e.message}"
            session[:flash] = flash.to_hash
            routing.redirect '/'
          end
        end
      end
    end
  end
end
