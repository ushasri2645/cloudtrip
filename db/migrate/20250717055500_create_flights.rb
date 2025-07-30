class CreateFlights < ActiveRecord::Migration[8.0]
  def change
    create_table :flights do |t|
      t.string :flight_number
      t.references :source, null: false, foreign_key: { to_table: :airports }
      t.references :destination, null: false, foreign_key: { to_table: :airports }
      t.datetime :departure_datetime
      t.datetime :arrival_datetime
      t.integer :total_seats
      t.decimal :price

      t.timestamps
    end
  end
end
