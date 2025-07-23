class RenameFlightSeatsAndCreateFlightScheduleSeats < ActiveRecord::Migration[8.0]
  def change
    rename_table :flight_seats, :base_flight_seats
    rename_column :base_flight_seats, :available_seats, :total_seats

    create_table :flight_schedule_seats do |t|
      t.references :flight_schedule, null: false, foreign_key: true
      t.references :seat_class, null: false, foreign_key: true
      t.integer :available_seats, null: false
      t.timestamps
    end
  end
end
