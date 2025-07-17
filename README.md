# ✈️ CloudTrip – Flight Booking API

CloudTrip is a **Rails backend API** for searching and booking flights. It uses simple file-based storage (`data.txt`) and dynamic pricing logic.

---

## 🛠️ Tech Stack

- **Ruby on Rails (API-only)**
- File-based storage (no DB)
- JSON responses
- CORS-enabled for frontend integration

---

### Schema Overview

- **Airport**: Holds city and code information.
- **Flight**: Stores flight details like source, destination, dates, and times.
- **SeatClass**: Represents seat types (Economy, Business, First Class).
- **FlightSeat**: Manages available seats for each class in a specific flight.
- **ClassPricing**: Stores pricing multipliers for each seat class per flight.

### ✅ Validations & Specs

All models include:

- **Validations** (e.g., presence, format, time logic)
- **RSpec model specs** (e.g., valid/invalid states)

---


## 🚀 Getting Started

```bash
git clone https://github.com/ushasri2645/cloudtrip.git
cd cloudtrip
```
### Installation
```bash
bundle install
```

### Set up DB
```bash
rails db:create db:migrate
```

### Run specs
```bash
bundle exec rspec
```
### Run app
```bash
bundle exec rails server
```

API runs at:  
```
http://localhost:3000/api
```

---

## Contact

- **Author:** Usha Sri Gudikandula  
- **GitHub:** [ushasri2645](https://github.com/ushasri2645)
