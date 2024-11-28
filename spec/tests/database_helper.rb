# frozen_string_literal: true

# spec/helpers/database_helper.rb

require 'sequel'

# Helper module for database operations
module DatabaseHelper
  def self.wipe_database
    # Assuming `app.db` provides access to the Sequel database connection
    db = WanderWise::App.db

    # Use transaction for safe, atomic operation
    db.transaction do
      db.tables.each do |table|
        db[table].truncate(cascade: true, restart: true) unless table == :schema_migrations
      end
    end
  end
end
