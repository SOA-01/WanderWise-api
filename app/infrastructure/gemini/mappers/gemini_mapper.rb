# frozen_string_literal: true

module WanderWise
  class GeminiMapper # rubocop:disable Style/Documentation
    def initialize(gateway)
      @gateway = gateway
    end

    def get_opinion(prompt) # rubocop:disable Metrics/AbcSize
      response = @gateway.gemini_api_call(prompt)
      text = ''
      response.each do |res|
        next unless res['candidates'] && res['candidates'].first['content'] && res['candidates'].first['content']['parts']

        text += res['candidates'].first['content']['parts'].first['text']
      end
      text
    end
  end
end
