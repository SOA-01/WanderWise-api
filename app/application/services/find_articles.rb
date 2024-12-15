# frozen_string_literal: true

require 'dry/transaction'
require 'logger'

module WanderWise
  module Service
    # Service to store article data
    class FindArticles
      include Dry::Transaction

      step :find_articles

      private

      def find_articles(input)
        result = articles_from_news_api(input)

        if result.failure?
          logger.error("Failed to find articles: #{result.failure}")
          return result
        end

        Success(result.value!)
      rescue StandardError => e
        logger.error("Error finding articles: #{e.message}")
        Failure('No articles found for the given criteria.')
      end

      def articles_from_news_api(input) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        logger.info('Creating article mapper')
        api_gateway = NYTimesAPI.new
        article_mapper = ArticleMapper.new(api_gateway)
        logger.info("Finding articles for: #{input}")
        articles = article_mapper.find_articles(input)
        logger.debug("Articles from: #{articles.first(2)}")
        if articles.nil? || articles.empty?
          logger.error("No articles found for the given criteria: #{input}")
          return Failure('No articles found for the given criteria.')
        end
        Success(articles)
      rescue StandardError
        logger.error("Unexpected result from article mapper: #{articles}")
        Failure('Unexpected error finding articles')
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
