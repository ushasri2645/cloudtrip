require 'rails_helper'

RSpec.describe FlightScheduleSeat, type: :model do
  describe "associations" do
    it { should belong_to(:flight_schedule) }
    it { should belong_to(:seat_class) }
  end
end
