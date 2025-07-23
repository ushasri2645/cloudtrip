class Flight < ApplicationRecord
  belongs_to :source, class_name: "Airport"
  belongs_to :destination, class_name: "Airport"

  has_many :base_flight_seats, dependent: :destroy
  has_many :seat_classes, through: :flight_seats
  has_one :flight_recurrence, dependent: :destroy
  has_many :flight_schedules, dependent: :destroy

  validates :flight_number, presence: true
  validates :departure_time,  presence: true
end
