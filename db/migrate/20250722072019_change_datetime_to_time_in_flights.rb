class ChangeDatetimeToTimeInFlights < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        rename_column :flights, :departure_datetime, :departure_time
        rename_column :flights, :arrival_datetime, :arrival_time

        change_column :flights, :departure_time, :time
        change_column :flights, :arrival_time, :time
      end

      dir.down do
        change_column :flights, :departure_time, :datetime
        change_column :flights, :arrival_time, :datetime

        rename_column :flights, :departure_time, :departure_datetime
        rename_column :flights, :arrival_time, :arrival_datetime
      end
    end
  end
end
