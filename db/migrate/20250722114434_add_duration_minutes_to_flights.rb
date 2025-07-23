class AddDurationMinutesToFlights < ActiveRecord::Migration[6.0]
  def up
    add_column :flights, :duration_minutes, :integer

    # Populate duration from existing arrival_time and departure_time
    Flight.reset_column_information

    Flight.find_each do |flight|
      if flight.arrival_time && flight.departure_time
        duration = (
          Time.zone.parse(flight.arrival_time.strftime("%H:%M")) -
          Time.zone.parse(flight.departure_time.strftime("%H:%M"))
        ) / 60

        # Handle next-day arrivals (negative durations)
        duration += 1440 if duration < 0

        flight.update_column(:duration_minutes, duration.to_i)
      end
    end

    # Optional: enforce not null and default
    change_column_null :flights, :duration_minutes, false, 0
    change_column_default :flights, :duration_minutes, 0
  end

  def down
    remove_column :flights, :duration_minutes
  end
end
