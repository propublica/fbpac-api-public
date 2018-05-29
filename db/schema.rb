# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180515191728) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "fuzzystrmatch"

  create_table "__diesel_schema_migrations", primary_key: "version", force: :cascade do |t|
    t.datetime "run_on", default: "now()", null: false
  end

  create_table "ads", force: :cascade do |t|
    t.text     "html",                                    null: false
    t.integer  "political",                               null: false
    t.integer  "not_political",                           null: false
    t.text     "title",                                   null: false
    t.text     "message",                                 null: false
    t.text     "thumbnail",                               null: false
    t.datetime "created_at",            default: "now()", null: false
    t.datetime "updated_at",            default: "now()", null: false
    t.text     "lang",                                    null: false
    t.text     "images",                                  null: false, array: true
    t.integer  "impressions",           default: 1,       null: false
    t.float    "political_probability", default: 0.0,     null: false
    t.text     "targeting"
    t.boolean  "suppressed",            default: false,   null: false
    t.jsonb    "targets",               default: []
    t.text     "advertiser"
    t.jsonb    "entities",              default: []
    t.text     "page"
    t.string   "lower_page"
  end

  add_index "ads", ["advertiser"], name: "index_ads_on_advertiser", using: :btree
  add_index "ads", ["entities"], name: "index_ads_on_entities", using: :gin
  add_index "ads", ["lang"], name: "index_ads_on_browser_lang", using: :btree
  add_index "ads", ["lang"], name: "index_ads_on_lang", using: :btree
  add_index "ads", ["lower_page"], name: "ads_lower_page_idx", using: :btree
  add_index "ads", ["page"], name: "index_ads_on_page", using: :btree
  add_index "ads", ["political_probability", "lang", "suppressed"], name: "index_ads_on_political_probability_lang_and_suppressed", using: :btree
  add_index "ads", ["political_probability"], name: "index_ads_on_political_probability", using: :btree
  add_index "ads", ["suppressed"], name: "index_ads_on_suppressed", using: :btree
  add_index "ads", ["targets"], name: "index_ads_on_targets", using: :gin

  create_table "candidates", force: :cascade do |t|
    t.string   "name"
    t.string   "facebook_url"
    t.string   "office"
    t.string   "state"
    t.string   "district"
    t.string   "party"
    t.string   "facebook_page_id"
    t.string   "country"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "close_races", force: :cascade do |t|
    t.string   "state"
    t.integer  "district"
    t.string   "country"
    t.string   "office"
    t.boolean  "interesting"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "electoral_districts", force: :cascade do |t|
    t.string   "state"
    t.string   "name"
    t.string   "office"
    t.string   "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "electoral_districts", ["state", "country"], name: "state_country_districts_idx", using: :btree

  create_table "parties", force: :cascade do |t|
    t.string   "name"
    t.string   "abbrev"
    t.string   "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partners", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "partners", ["email"], name: "index_partners_on_email", unique: true, using: :btree
  add_index "partners", ["reset_password_token"], name: "index_partners_on_reset_password_token", unique: true, using: :btree
  add_index "partners", ["unlock_token"], name: "index_partners_on_unlock_token", unique: true, using: :btree

  create_table "states", force: :cascade do |t|
    t.string   "name"
    t.string   "abbrev"
    t.string   "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
