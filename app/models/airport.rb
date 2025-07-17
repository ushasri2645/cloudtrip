class Airport < ApplicationRecord
    has_many :departing_flights, class_name: "Flight", foreign_key: :source_id, inverse_of: :source, dependent: :destroy
    has_many :arriving_flights, class_name: "Flight", foreign_key: :destination_id, inverse_of: :source, dependent: :destroy

    validates :city, presence: true
    validates :code, presence: true
end
