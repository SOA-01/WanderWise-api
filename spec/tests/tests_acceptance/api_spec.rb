# frozen_string_literal: true

require 'rspec'
require 'yaml'
require 'simplecov'
require 'rack/test'
SimpleCov.start

require_relative '../../../app/infrastructure/database/repositories/for'
require_relative '../../../app/infrastructure/database/repositories/flights'
require_relative '../../../app/infrastructure/database/repositories/articles'
require_relative '../../../app/infrastructure/database/repositories/entity'
require_relative '../spec_helper'

def app
  WanderWise::App
end

RSpec.describe 'API Acceptance Tests' do
  include Rack::Test::Methods

  describe 'Root route' do
    it 'returns API metadata' do
      get '/'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['status']).to eq('ok')
      expect(body['message']).to include('api/v1')
    end
  end

  describe 'Flight search submit route' do
    let(:valid_params) do
      {
        originLocationCode: 'TPE',
        destinationLocationCode: 'LAX',
        departureDate: (Date.today + 7).to_s,
        adults: 1
      }
    end
    # make params url parameters

    context 'when parameters are valid' do
      it 'returns a success response with flights data' do
        post '/api/v1/submit', valid_params, 'rack.session' => { watching: [] }
        expect(last_response.status).to eq(201)
        body = JSON.parse(last_response.body)
        expect(body).to have_key('flights')
        expect(body['flights']).to be_an(Array)
      end
    end

    # context 'when parameters are missing or invalid' do
    #   it 'returns an error response' do
    #     post '/submit', {}, 'rack.session' => { watching: [] }
    #     expect(last_response.status).to eq(400)
    #     body = JSON.parse(last_response.body)
    #     expect(body['error']).to eq('Invalid parameters')
    #   end
    # end
  end

  describe 'Articles route' do
    it 'retrieves a list of articles' do
      get '/articles'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to have_key('articles')
      expect(body['articles']).to be_an(Array)
      expect(body['articles'].first).to have_key('title')
      expect(body['articles'].first).to have_key('content')
    end
  end
end
