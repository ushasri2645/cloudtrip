class AddUniqueIndexesToFlightSchema < ActiveRecord::Migration[8.0]
  def change
    add_index :airports, :code, unique: true
    add_index :flights, [ :flight_number, :source_id, :destination_id ], unique: true, name: "index_flights_on_number_and_route"
    add_index :flight_schedules, [ :flight_id, :flight_date ], unique: true
    add_index :flight_schedule_seats, [ :flight_schedule_id, :seat_class_id ], unique: true, name: "index_schedule_seats_on_schedule_and_class"
    add_index :base_flight_seats, [ :flight_id, :seat_class_id ], unique: true
  end
end
