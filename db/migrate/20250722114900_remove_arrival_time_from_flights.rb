class RemoveArrivalTimeFromFlights < ActiveRecord::Migration[8.0]
  def change
    remove_column :flights, :arrival_time, :time
  end
end
