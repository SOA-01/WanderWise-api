# frozen_string_literal: true

require 'gemini-ai'
require 'yaml'

module WanderWise
  class GeminiAPI # rubocop:disable Style/Documentation
    def initialize # rubocop:disable Metrics/MethodLength
      environment = ENV['RACK_ENV'] || 'development'

      unless environment == 'production'
        secrets_file_path = './config/secrets.yml'
        raise "secrets.yml file not found for #{environment} environment." unless File.exist?(secrets_file_path)

        YAML.load_file(secrets_file_path)
      end

      @client_key = ENV['GEMINI_API_KEY'] || 'N/A'

      @client = Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: @client_key
        },
        options: { model: 'gemini-pro', server_sent_events: true }
      )
    end

    def gemini_api_call(prompt)
      @client.stream_generate_content({ contents: { role: 'user', parts: { text: prompt } } })
    end
  end
end
