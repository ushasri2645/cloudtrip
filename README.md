# ✈️ CloudTrip – Flight Booking Console Application

CloudTrip is a simple yet powerful **flight booking system** built with Ruby that enables users to search and book flights based on multiple criteria. The application uses **file-based storage** (`data.txt`) to manage flight availability and booking information.

---

## 📌 Features

### Basic Flight Search
- Search for flights by entering **source** and **destination**.
- Only flights with **available seats** are shown.
- If no flights are found, the system displays: `"No Flights Available"`.

### Search by Departure Date
- Include a **departure date** in your search.
- View **departure and arrival times** in the results.

### Available Seats Filter
- System filters out all **fully booked** flights automatically.

### Input Number of Passengers
- Enter how many passengers you're booking for.
- Only flights with **enough seats** will be displayed.

### Filter by Class Type
- Choose between:
  - Economic
  - Second
  - First class
- Results show only flights with seats available in the selected class.

### Fare Estimation
- The system calculates **total fare** based on:
  - Class type
  - Number of passengers
  - Base price
  - Pricing strategy (dynamic pricing)

### Dynamic Pricing Logic
- Seat-based pricing
- Date-based pricing

### ✅ Round Trip Support *(Optional)*
- Book **round trips** with a **5% discount**.
- Return flights must also match passenger and class criteria.

---

## 📁 File-Based Storage

### 📄 `data.txt` Format:
```text
FlightID, "From", "To", DepartureTime, ArrivalTime, ClassType, BasePrice, AvailableSeats
```

## 🚀 Installation

Follow these steps to set up and run **CloudTrip** locally:

### 1. Clone the Repository

```bash
git clone https://github.com/ushasri2645/cloudtrip.git
cd cloudtrip
```

### 2. Install dependencies 
```bash
bundle install
```

### 3. Run the server
```bash
bundle exec rails server
```

### 4. Visit 
```bash
htttp://localhost:3000
```

## Contact

Questions, feedback, or contributions are welcome!

- **Author:** Usha Sri Gudikandula
- **Email:** ugudikandula@everest.engineering
- **GitHub:** [github.com/ushasri2645](https://github.com/ushasri2645)

Feel free to open an issue or a pull request!
