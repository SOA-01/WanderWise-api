# frozen_string_literal: true

require 'rake/testtask'

CODE = 'app/application/controllers'

# Default task for Puma
task :default do
  if ENV['RACK_ENV'] == 'production'
    sh 'bundle exec puma -9 9090'
  else
    sh 'RACK_ENV=development bundle exec puma -p 9090'
  end
end

# Run tests for a merged coverage report
task :test do
  if ENV['RACK_ENV'] == 'production'
    puts 'Running tests in production mode'
    sh 'RACK_ENV=production COVERAGE=1 rspec spec/tests/app_spec.rb'
    sh 'RACK_ENV=production COVERAGE=1 rspec spec/tests/api_spec.rb'
    sh 'RACK_ENV=production COVERAGE=1 rspec spec/tests/data_mapper_spec.rb'
  else
    puts 'Running tests in development mode'
    sh 'RACK_ENV=development COVERAGE=1 rspec spec/tests/app_spec.rb'
    sh 'RACK_ENV=development COVERAGE=1 rspec spec/tests/api_spec.rb'
    sh 'RACK_ENV=development COVERAGE=1 rspec spec/tests/data_mapper_spec.rb'
  end
end

task :spec do
  ruby 'spec/tests/spec_helper.rb'
end

task :new_session_secret do
  require 'base64'
  require 'securerandom'
  secret = SecureRandom.random_bytes(64).then { Base64.urlsafe_encode64(_1) }
  puts "SESSION_SECRET: #{secret}"
end

namespace :vcr do
  desc 'delete all cassettes'
  task :delete do
    rm_rf 'spec/cassettes'
  end
end

namespace :quality do
  desc 'run all quality checks'
  task all: %i[rubocop reek flog]
  task :rubocop do
    sh 'rubocop'
  end
  task :reek do
    sh 'reek'
  end
  task :flog do
    sh "flog#{CODE}"
  end
end

namespace :db do # rubocop:disable Metrics/BlockLength
  task :config do
    require 'sequel'
    require_relative 'config/environment' # load config info
    require_relative 'spec/tests/database_helper'
    def app = WanderWise::App
  end

  desc 'Run migrations'
  task migrate: :config do
    Sequel.extension :migration
    puts "Migrating #{app.environment} database to latest"
    puts "Migration path: #{Dir.pwd}/db/migrations"
    puts 'Files in migration path:'
    puts Dir.entries('db/migrations') # This should list your migration files
    Sequel::Migrator.run(app.db, 'db/migrations')
  end

  task migrate_test: :config do
    Sequel.extension :migration
    puts 'Migrating test database to latest'
    puts "Migration path: #{Dir.pwd}/db/migrations"
    puts 'Files in migration path:'
    puts Dir.entries('db/migrations') # This should list your migration files
    Sequel::Migrator.run(app.db, 'db/migrations')
  end

  desc 'Wipe records from all tables'
  task wipe: :config do
    if app.environment == :production
      puts 'Do not damage production database!'
      return
    end

    DatabaseHelper.wipe_database
  end

  desc 'Delete dev or test database file (set correct RACK_ENV)'
  task drop: :config do
    if app.environment == :production
      puts 'Do not damage production database!'
      return
    end
    FileUtils.rm(WanderWise::App.config.DB_FILENAME)
    puts "Deleted #{WanderWise::App.config.DB_FILENAME}"
  end

  task drop_test: :config do
    if app.environment == :production
      puts 'Do not damage production database!'
      return
    end
    FileUtils.rm(WanderWise::App.config.DB_FILENAME)
    puts "Deleted #{WanderWise::App.config.DB_FILENAME}"
  end
end

desc 'Run app console (irb)'
task :console do
  sh 'pry -r ./load_all.rb'
end
