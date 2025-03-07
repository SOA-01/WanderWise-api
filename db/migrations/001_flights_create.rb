# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:flights) do
      primary_key :id
      String      :origin_location_code
      String      :destination_location_code
      Float       :price
      String      :airline, null: false
      String      :duration, null: false
      Time        :departure_time, null: false
      Time        :arrival_time, null: false
      Date        :departure_date, null: false
    end
  end
end
