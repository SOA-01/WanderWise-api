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

      def articles_from_news_api(input)
        news_api = NYTimesAPI.new
        article_mapper = ArticleMapper.new(news_api)
        result = article_mapper.find_articles(input)
      
        case result
        when Success
          articles = result.value!
          if articles.nil? || articles.empty?
            logger.error("No articles found for the given criteria: #{input}")
            return Failure('No articles found for the given criteria.')
          end
        when Failure
          return result
        else
          logger.error("Unexpected result from article mapper: #{result}")
          return Failure('Unexpected error finding articles')
        end
      
        Success(articles)
      end      

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
