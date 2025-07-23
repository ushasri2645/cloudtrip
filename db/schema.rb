# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_22_114900) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "airports", force: :cascade do |t|
    t.string "city"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "base_flight_seats", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.bigint "seat_class_id", null: false
    t.integer "total_seats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price"
    t.index ["flight_id"], name: "index_base_flight_seats_on_flight_id"
    t.index ["seat_class_id"], name: "index_base_flight_seats_on_seat_class_id"
  end

  create_table "flight_recurrences", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.integer "days_of_week", default: [], null: false, array: true
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_flight_recurrences_on_flight_id"
  end

  create_table "flight_schedule_seats", force: :cascade do |t|
    t.bigint "flight_schedule_id", null: false
    t.bigint "seat_class_id", null: false
    t.integer "available_seats", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_schedule_id"], name: "index_flight_schedule_seats_on_flight_schedule_id"
    t.index ["seat_class_id"], name: "index_flight_schedule_seats_on_seat_class_id"
  end

  create_table "flight_schedules", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.date "flight_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_flight_schedules_on_flight_id"
  end

  create_table "flights", force: :cascade do |t|
    t.string "flight_number"
    t.bigint "source_id", null: false
    t.bigint "destination_id", null: false
    t.time "departure_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_recurring", default: true, null: false
    t.integer "duration_minutes", default: 0, null: false
    t.index ["destination_id"], name: "index_flights_on_destination_id"
    t.index ["source_id"], name: "index_flights_on_source_id"
  end

  create_table "seat_classes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "base_flight_seats", "flights"
  add_foreign_key "base_flight_seats", "seat_classes"
  add_foreign_key "flight_recurrences", "flights"
  add_foreign_key "flight_schedule_seats", "flight_schedules"
  add_foreign_key "flight_schedule_seats", "seat_classes"
  add_foreign_key "flight_schedules", "flights"
  add_foreign_key "flights", "airports", column: "destination_id"
  add_foreign_key "flights", "airports", column: "source_id"
end
