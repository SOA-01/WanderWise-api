# frozen_string_literal: true

require 'dry/transaction'

module WanderWise
  module Service
    # Service to get opinion
    class GetOpinion
      include Dry::Transaction

      step :get_opinion

      private

      def get_opinion(input)
        opinion = opinion_from_gemini(input)

        if opinion.failure?
          # Log the failure details
          logger.error("Failed to find opinion: #{opinion.failure}")
          return opinion
        end

        Success(opinion)
      rescue StandardError => e
        logger.error("Error getting opinion: #{e.message}")
        Failure('Unable to get opinion.')
      end

      def opinion_from_gemini(input) # rubocop:disable Metrics/MethodLength
        prompt = construct_prompt(input)

        puts "Prompt: #{prompt}"

        gemini_api = GeminiAPI.new
        gemini_mapper = GeminiMapper.new(gemini_api)

        gemini_answer = gemini_mapper.get_opinion(prompt)

        if gemini_answer.empty? || gemini_answer.nil?
          logger.error("No opinion found for the given criteria: #{input}")
          return Failure('No opinion found for the given criteria.')
        end

        logger.debug("Opinion retrieved: #{gemini_answer}")
        Success(gemini_answer)
      end

      def construct_prompt(input)
        destination = input['destination']
        month = input['month']
        origin = input['origin']
        historical_flight_data = input['historical_average_data']
        nytimes_articles = input['nytimes_articles']

        "What is your opinion on travelling to #{destination} in month number #{month}? " \
        "Based on my findings, the average price for a flight from #{origin} " \
        "to #{destination} is $#{historical_flight_data}. " \
        'Does the average price seem reasonable? ' \
        "Does it seem safe based on recent news articles: #{nytimes_articles}?"
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
