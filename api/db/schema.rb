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

ActiveRecord::Schema[7.2].define(version: 2026_05_30_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "plpgsql"

  create_table "appointment_requests", force: :cascade do |t|
    t.bigint "nutritionist_id", null: false
    t.bigint "service_id", null: false
    t.string "guest_name", null: false
    t.string "guest_email", null: false
    t.timestamptz "starts_at", null: false
    t.timestamptz "ends_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_email"], name: "index_appointment_requests_on_guest_email"
    t.index ["guest_email"], name: "index_appointment_requests_unique_pending_per_guest", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["nutritionist_id", "status"], name: "index_appointment_requests_on_nutritionist_id_and_status"
    t.index ["nutritionist_id"], name: "index_appointment_requests_on_nutritionist_id"
    t.index ["service_id"], name: "index_appointment_requests_on_service_id"
    t.check_constraint "ends_at > starts_at", name: "ends_after_starts"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'accepted'::character varying, 'rejected'::character varying]::text[])", name: "status_in_enum"
    t.exclusion_constraint "nutritionist_id WITH =, tstzrange(starts_at, ends_at) WITH &&", where: "(status)::text = 'accepted'::text", using: :gist, name: "no_overlapping_accepted"
  end

  create_table "nutritionists", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "license_number"
    t.string "photo_url"
    t.text "bio"
    t.index ["email"], name: "index_nutritionists_on_email", unique: true, where: "(email IS NOT NULL)"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "nutritionist_id", null: false
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.string "location", null: false
    t.integer "duration_minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.index ["location"], name: "index_services_on_location"
    t.index ["nutritionist_id"], name: "index_services_on_nutritionist_id"
    t.check_constraint "duration_minutes > 0", name: "duration_minutes_positive"
    t.check_constraint "price_cents >= 0", name: "price_cents_non_negative"
  end

  add_foreign_key "appointment_requests", "nutritionists"
  add_foreign_key "appointment_requests", "services"
  add_foreign_key "services", "nutritionists"
end
