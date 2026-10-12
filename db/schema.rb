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

ActiveRecord::Schema[8.1].define(version: 2026_10_12_054706) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "crew_members", force: :cascade do |t|
    t.bigint "crew_id", null: false
    t.integer "group_code", null: false
    t.string "name"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_id"], name: "index_crew_members_on_crew_id"
    t.index ["token"], name: "index_crew_members_on_token", unique: true
  end

  create_table "crews", force: :cascade do |t|
    t.string "name", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_crews_on_token", unique: true
  end

  create_table "lines", force: :cascade do |t|
    t.integer "code"
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "symbol"
    t.index ["code"], name: "index_lines_on_code", unique: true
  end

  create_table "segments", force: :cascade do |t|
    t.integer "line_code"
    t.integer "from_code"
    t.integer "to_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_code"], name: "index_segments_on_from_code"
    t.index ["line_code"], name: "index_segments_on_line_code"
    t.index ["to_code"], name: "index_segments_on_to_code"
  end

  create_table "stations", force: :cascade do |t|
    t.integer "code"
    t.integer "group_code"
    t.string "name"
    t.string "name_romaji"
    t.integer "line_code"
    t.integer "pref_code"
    t.float "lat"
    t.float "lon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name_kana"
    t.string "search_key"
    t.string "numbering"
    t.index ["code"], name: "index_stations_on_code", unique: true
    t.index ["group_code"], name: "index_stations_on_group_code"
    t.index ["line_code"], name: "index_stations_on_line_code"
    t.index ["search_key"], name: "index_stations_on_search_key"
  end

  create_table "visits", force: :cascade do |t|
    t.bigint "crew_id", null: false
    t.integer "group_code", null: false
    t.string "place_name", null: false
    t.string "genre"
    t.string "budget"
    t.string "url"
    t.string "photo"
    t.string "logged_by"
    t.date "visited_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_id", "group_code", "place_name"], name: "index_visits_on_crew_id_and_group_code_and_place_name"
    t.index ["crew_id"], name: "index_visits_on_crew_id"
  end

  add_foreign_key "crew_members", "crews"
  add_foreign_key "visits", "crews"
end
