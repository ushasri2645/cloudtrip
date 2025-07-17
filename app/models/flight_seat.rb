class FlightSeat < ApplicationRecord
  belongs_to :flight
  belongs_to :seat_class

  validates :total_seats, :available_seats, presence: true,
  numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :available_less_than_total

  def available_less_than_total
    return if available_seats.blank? || total_seats.blank?
    errors.add(:available_seats, "can't be more than total seats") if available_seats > total_seats
  end
end
