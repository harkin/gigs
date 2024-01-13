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

ActiveRecord::Schema[7.1].define(version: 2024_01_13_212024) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.string "price"
    t.string "link_to_buy_ticket"
    t.string "more_info"
    t.integer "ticket_status", null: false
    t.integer "venue", null: false
    t.datetime "event_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["venue"], name: "index_events_on_venue"
  end

  create_table "refreshes", force: :cascade do |t|
    t.datetime "last_refresh_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
