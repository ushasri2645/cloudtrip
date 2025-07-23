class SeatClass < ApplicationRecord
    has_many :base_flight_seats, dependent: :destroy
    has_many :flights, through: :flight_seats
    has_many :flight_schedule_seats, dependent: :destroy

    validates :name, presence: true
end
