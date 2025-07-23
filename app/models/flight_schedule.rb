class FlightSchedule < ApplicationRecord
    belongs_to :flight
    has_many :flight_schedule_seats, dependent: :destroy
end
