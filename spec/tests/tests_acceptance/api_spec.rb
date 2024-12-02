# frozen_string_literal: true

require 'rspec'
require 'yaml'
require 'simplecov'
require 'rack/test'
SimpleCov.start

require_relative '../spec_helper'
require_relative '../../../app/infrastructure/database/repositories/for'
require_relative '../../../app/infrastructure/database/repositories/flights'
require_relative '../../../app/infrastructure/database/repositories/articles'
require_relative '../../../app/infrastructure/database/repositories/entity'

def app
  WanderWise::App
end

RSpec.describe 'Test API routes' do
  include Rack::Test::Methods
  # VCR and Database setup

  describe 'Root route' do
    it 'should successfully return root information' do
      get '/'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['status']).to eq('ok')
      expect(body['message']).to include('api/v1')
    end
  end

  describe 'Load results' do
    it 'should be able to get response' do
      date_next_week = (Date.today + 7).to_s
      params = { originLocationCode: 'TPE', destinationLocationCode: 'LAX', departureDate: date_next_week, adults: 1 }
      URI.encode_www_form(params)

      post '/submit', params, 'rack.session' => { watching: [] }

      expect(last_response.status).to eq(201)
      JSON.parse(last_response.body)
      expect(project['name']).to eq(PROJECT_NAME)
      expect(project['owner']['username']).to eq(USERNAME)
    end
  end
end
