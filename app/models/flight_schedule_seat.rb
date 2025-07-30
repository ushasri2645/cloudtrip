class FlightScheduleSeat < ApplicationRecord
  belongs_to :flight_schedule
  belongs_to :seat_class
end
