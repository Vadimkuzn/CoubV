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

ActiveRecord::Schema.define(version: 20160804130316) do

  create_table "coub_tasks", force: :cascade do |t|
    t.integer  "user_id",                                   null: false
    t.string   "title",         limit: 255
    t.string   "type",          limit: 255,                 null: false
    t.string   "url",           limit: 255,                 null: false
    t.integer  "cost",                                      null: false
    t.string   "item_id",       limit: 255,                 null: false
    t.string   "shortcode",     limit: 255
    t.boolean  "deleted",                   default: false, null: false
    t.boolean  "paused",                    default: false, null: false
    t.boolean  "suspended",                 default: false, null: false
    t.boolean  "verified",                  default: false, null: false
    t.integer  "current_count",                             null: false
    t.integer  "max_count",                                 null: false
    t.integer  "members_count",                             null: false
    t.string   "picture_path",  limit: 255
    t.boolean  "finished",                  default: false, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "coub_tasks_users", force: :cascade do |t|
    t.integer  "user_id",                                  null: false
    t.integer  "coub_task_id",                             null: false
    t.string   "coub_id",      limit: 255,                 null: false
    t.boolean  "state"
    t.boolean  "panished",                 default: false, null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "auth_token"
    t.string   "name"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "money",         default: 0, null: false
    t.string   "premium_type"
    t.datetime "premium_until"
  end

end
