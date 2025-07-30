class CreateFlightSeats < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_seats do |t|
      t.references :flight, null: false, foreign_key: true
      t.references :seat_class, null: false, foreign_key: true
      t.integer :total_seats
      t.integer :available_seats

      t.timestamps
    end
  end
end
