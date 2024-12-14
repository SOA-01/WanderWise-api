# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../../../../app/application/services/find_articles'

RSpec.describe WanderWise::Service::FindArticles do # rubocop:disable Metrics/BlockLength
  let(:find_articles_service) { described_class.new }
  let(:input) { 'United States' }
  let(:mock_news_api) { instance_double('NYTimesAPI') }
  let(:mock_article_mapper) { instance_double('ArticleMapper') }
  let(:articles) do
    [
      { title: 'Tech Innovations', url: 'http://example.com/article1' },
      { title: 'AI Advances', url: 'http://example.com/article2' }
    ]
  end

  before do
    allow(WanderWise::NYTimesAPI).to receive(:new).and_return(mock_news_api)
    allow(WanderWise::ArticleMapper).to receive(:new).with(mock_news_api).and_return(mock_article_mapper)
  end

  describe '#find_articles' do # rubocop:disable Metrics/BlockLength
    context 'when articles are found successfully' do
      before do
        allow(mock_article_mapper).to receive(:find_articles).with(input).and_return(Dry::Monads::Success(articles))
      end

      it 'returns Success with the articles' do
        result = find_articles_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(articles)
      end
    end

    context 'when no articles are found' do
      before do
        allow(mock_article_mapper).to receive(:find_articles).with(input).and_return(Dry::Monads::Failure('No articles found for the given criteria.'))
      end

      it 'returns Failure with an appropriate message' do
        result = find_articles_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('No articles found for the given criteria.')
      end
    end

    context 'when an error occurs during the process' do
      before do
        allow(mock_article_mapper).to receive(:find_articles).with(input).and_raise(StandardError, 'Unexpected error')
      end

      it 'returns Failure with a generic error message' do
        result = find_articles_service.call(input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('No articles found for the given criteria.')
      end
    end
  end

  describe '#articles_from_news_api' do
    context 'when articles are retrieved successfully' do
      before do
        allow(mock_article_mapper).to receive(:find_articles).with(input).and_return(Dry::Monads::Success(articles))
      end

      it 'returns Success with the articles' do
        result = find_articles_service.send(:articles_from_news_api, input)

        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq(articles)
      end
    end

    context 'when no articles are retrieved' do
      before do
        allow(mock_article_mapper).to receive(:find_articles).with(input).and_return(Dry::Monads::Failure('No articles found for the given criteria.'))
      end

      it 'returns Failure with a specific message' do
        result = find_articles_service.send(:articles_from_news_api, input)

        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq('No articles found for the given criteria.')
      end
    end
  end
end
