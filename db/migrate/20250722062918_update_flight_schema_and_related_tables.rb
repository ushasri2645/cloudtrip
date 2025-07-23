class UpdateFlightSchemaAndRelatedTables < ActiveRecord::Migration[8.0]
  def change
    change_table :flights, bulk: true do |t|
      t.boolean :is_recurring, default: true, null: false
    end

    reversible do |dir|
      dir.up do
        change_table :flights, bulk: true do |t|
          t.remove :price
          t.remove :total_seats
        end
      end

      dir.down do
        change_table :flights, bulk: true do |t|
          t.decimal :price
          t.integer :total_seats
        end
      end
    end

    reversible do |dir|
      dir.up do
        drop_table :class_pricings
      end

      dir.down do
        create_table :class_pricings do |t|
          t.references :flight, null: false, foreign_key: true
          t.references :seat_class, null: false, foreign_key: true
          t.decimal :multiplier
          t.timestamps
        end
      end
    end

    reversible do |dir|
      dir.up do
        change_table :flight_seats, bulk: true do |t|
          t.remove :total_seats
          t.decimal :price
        end
      end

      dir.down do
        change_table :flight_seats, bulk: true do |t|
          t.integer :total_seats
          t.remove :price
        end
      end
    end

    create_table :flight_recurrences do |t|
      t.references :flight, null: false, foreign_key: true
      t.integer :days_of_week, array: true, null: false, default: []
      t.date :start_date, null: false
      t.date :end_date
      t.timestamps
    end

    create_table :flight_schedules do |t|
      t.references :flight, null: false, foreign_key: true
      t.date :flight_date, null: false
      t.timestamps
    end
  end
end
