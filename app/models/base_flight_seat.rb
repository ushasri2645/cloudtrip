class BaseFlightSeat < ApplicationRecord
  belongs_to :flight
  belongs_to :seat_class

  validates :total_seats, presence: true,
  numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
