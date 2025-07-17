class ClassPricing < ApplicationRecord
  belongs_to :flight
  belongs_to :seat_class

  validates :multiplier, presence: true,
  numericality: { greater_than_or_equal_to: 1 }
end
