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

ActiveRecord::Schema[8.0].define(version: 2025_07_17_060355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "airports", force: :cascade do |t|
    t.string "city"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "class_pricings", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.bigint "seat_class_id", null: false
    t.decimal "multiplier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_class_pricings_on_flight_id"
    t.index ["seat_class_id"], name: "index_class_pricings_on_seat_class_id"
  end

  create_table "flight_seats", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.bigint "seat_class_id", null: false
    t.integer "total_seats"
    t.integer "available_seats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_flight_seats_on_flight_id"
    t.index ["seat_class_id"], name: "index_flight_seats_on_seat_class_id"
  end

  create_table "flights", force: :cascade do |t|
    t.string "flight_number"
    t.bigint "source_id", null: false
    t.bigint "destination_id", null: false
    t.datetime "departure_datetime"
    t.datetime "arrival_datetime"
    t.integer "total_seats"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_flights_on_destination_id"
    t.index ["source_id"], name: "index_flights_on_source_id"
  end

  create_table "seat_classes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "class_pricings", "flights"
  add_foreign_key "class_pricings", "seat_classes"
  add_foreign_key "flight_seats", "flights"
  add_foreign_key "flight_seats", "seat_classes"
  add_foreign_key "flights", "airports", column: "destination_id"
  add_foreign_key "flights", "airports", column: "source_id"
end
