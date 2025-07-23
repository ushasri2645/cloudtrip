require 'rails_helper'

RSpec.describe FlightSchedule, type: :model do
  describe "associations" do
    it { should belong_to(:flight) }
    it { should have_many(:flight_schedule_seats).dependent(:destroy) }
  end
end
