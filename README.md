# ✈️ CloudTrip – Flight Booking API

CloudTrip is a **Rails backend API** for searching and booking flights. It uses simple file-based storage (`data.txt`) and dynamic pricing logic.

---

## 🛠️ Tech Stack

- **Ruby on Rails (API-only)**
- File-based storage (no DB)
- JSON responses
- CORS-enabled for frontend integration

---

## 🔗 API Endpoints

- `GET /api/cities`  
  → Loads and returns all unique cities (only loaded once on app start for performance).

---

## 🗃️ Data File Format

```
flight_number,source,destination,departure_date,departure_time,arrival_date,arrival_time,total_seats,price,economy_seats,business_seats,first_class_seats,economy_total,business_total,first_class_total
```

Example:
```
AI101,New York,London,2025-07-15,09:00 AM,2025-07-15,09:00 PM,200,450.0,50,30,20,100,50,50
```

---

## 🚀 Getting Started

```bash
git clone https://github.com/ushasri2645/cloudtrip.git
cd cloudtrip
bundle install
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
