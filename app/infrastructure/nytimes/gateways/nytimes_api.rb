# frozen_string_literal: true

require 'http'
require 'yaml'
require 'json'
require 'date'
require_relative '../../../models/entities/article'

module WanderWise
  # Gateway to NY Times API for recent articles
  class NYTimesAPI
    def initialize
      # Set the environment from RACK_ENV or default to development
      environment = ENV['RACK_ENV'] || 'development'

      # Load secrets from environment variables for production or from secrets.yml for development
      if environment == 'production'
        # In production, use environment variables for API keys
        @api_key = ENV['NYTIMES_API_KEY']
        raise 'NYTIMES_API_KEY environment variable is missing!' if @api_key.nil?
      else
        # In non-production environments, load from secrets.yml
        secrets = load_secrets
        @api_key = secrets[environment]['nytimes_api_key']
      end

      @base_url = 'https://api.nytimes.com/svc/search/v2/articlesearch.json'

      # Create a fixture file for the API response if it doesn't exist in development/test
      save_to_fixtures unless File.exist?('./spec/fixtures/nytimes-api-results.yml') || environment == 'production'
    end

    # Fetch recent articles based on the keyword
    def fetch_recent_articles(keyword)
      today = DateTime.now
      one_week_ago = (today - 7).strftime('%Y%m%d')

      params = {
        'q' => keyword,
        'begin_date' => one_week_ago,
        'end_date' => today.strftime('%Y%m%d'),
        'api-key' => @api_key
      }

      # Return raw parsed JSON as a Ruby hash
      fetch_articles(params)
    end

    # Save the mock API response to fixtures for development/test environments
    def save_to_fixtures
      articles = fetch_recent_articles('travel')

      File.open('./spec/fixtures/nytimes-api-results.yml', 'w') { |file| file.write(articles.to_yaml) }
    end

    # Perform the API call and return the JSON response as a Ruby hash
    def fetch_articles(params)
      response = HTTP.get(@base_url, params: params)
      response_body = response.body.to_s.force_encoding('UTF-8')
      JSON.parse(response_body)
    rescue HTTP::Error => e
      handle_error(e)
    end

    private

    # Load secrets from secrets.yml for development/test environments
    def load_secrets
      secrets_file_path = './config/secrets.yml'
      raise "secrets.yml file not found" unless File.exist?(secrets_file_path)

      YAML.load_file(secrets_file_path)
    end

    # Handle HTTP API errors
    def handle_error(error)
      # You can log the error or handle it in a way that suits your application
      raise "Error fetching articles: #{error.message}"
    end
  end
end
