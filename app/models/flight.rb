class Flight < ApplicationRecord
  belongs_to :source, class_name: "Airport"
  belongs_to :destination, class_name: "Airport"

  has_many :flight_seats, dependent: :destroy
  has_many :seat_classes, through: :flight_seats

  has_many :class_pricings, dependent: :destroy

  validates :flight_number, presence: true
  validates :departure_datetime, :arrival_datetime, presence: true
  validates :total_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validate  :arrival_after_departure

  def departure_date
    departure_datetime&.to_date
  end

  def arrival_after_departure
    return if arrival_datetime.blank? || departure_datetime.blank?
    errors.add(:arrival_datetime, "must be after departure") if arrival_datetime <= departure_datetime
  end
end
