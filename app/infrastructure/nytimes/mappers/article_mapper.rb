# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module WanderWise
  # Mapper class for transforming API data into ArticlesEntity
  class ArticleMapper
    def initialize(gateway)
      @gateway = gateway
    end

    # Find and map articles to entity
    def find_articles(keyword)
      articles_data = fetch_articles_data(keyword)
      docs = ArticleDataExtractor.extract_docs(articles_data)
      # Map the articles to entities
      docs.map { |article_data| ArticleBuilder.build(article_data) }
    end

    def save_articles_to_yaml(keyword, file_path)
      articles = find_articles(keyword)
      DirectoryUtils.create_directory(file_path)

      File.open(file_path, 'w') do |file|
        file.write(articles.map(&:to_h).to_yaml)
      end

      articles
    end

    private

    def fetch_articles_data(keyword)
      @gateway.fetch_recent_articles(keyword)
    end
  end

  # Builder class for ArticleEntity
  class ArticleBuilder
    def self.build(article_data)
      Article.new(
        title: article_data.dig('headline', 'main'),
        published_date: article_data['pub_date'],
        url: article_data['web_url']
      )
    end
  end

  # Extractor class for articles data
  class ArticleDataExtractor
    def self.extract_docs(articles_data)
      response = articles_data['response']
      docs = response['docs']

      # Error handling for bad API responses
      unless articles_data.is_a?(Hash) && response.is_a?(Hash) && docs.is_a?(Array)
        raise "Unexpected response from NYTimes API: #{articles_data.inspect}"
      end

      docs
    end
  end

  # Utility module for directory operations
  module DirectoryUtils
    def self.create_directory(file_path)
      dir_path = File.dirname(file_path)
      FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
    end
  end
end
