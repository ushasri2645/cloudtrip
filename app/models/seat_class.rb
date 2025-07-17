class SeatClass < ApplicationRecord
    has_many :flight_seats, dependent: :destroy
    has_many :flights, through: :flight_seats

    has_many :class_pricings, dependent: :destroy
    validates :name, presence: true
end
