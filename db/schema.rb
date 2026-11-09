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

ActiveRecord::Schema[8.1].define(version: 2026_11_04_231641) do
  create_table "characters", force: :cascade do |t|
    t.string "type", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_characters_on_type"
  end

  create_table "padlock_passwords", force: :cascade do |t|
    t.string "key_digest", null: false
    t.integer "holder_id", null: false
    t.integer "replaced_by_id"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_padlock_passwords_on_expires_at"
    t.index ["holder_id"], name: "index_padlock_passwords_on_holder_id"
    t.index ["replaced_by_id"], name: "index_padlock_passwords_on_replaced_by_id"
  end

  create_table "padlock_usernames", force: :cascade do |t|
    t.text "key", null: false
    t.integer "holder_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holder_id"], name: "index_padlock_usernames_on_holder_id"
    t.index ["holder_id"], name: "padlock_usernames_unique_holder_id", unique: true
    t.index ["key"], name: "index_padlock_usernames_on_key", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "character_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_sessions_on_character_id"
  end

  add_foreign_key "padlock_passwords", "characters", column: "holder_id"
  add_foreign_key "padlock_passwords", "padlock_passwords", column: "replaced_by_id"
  add_foreign_key "padlock_usernames", "characters", column: "holder_id"
  add_foreign_key "sessions", "characters"
end
