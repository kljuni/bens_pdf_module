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

ActiveRecord::Schema[8.0].define(version: 2024_12_03_135022) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "document_data", force: :cascade do |t|
    t.string "document_hash", null: false
    t.binary "pdf_data", null: false
    t.jsonb "result_data"
    t.string "parse_state", default: "uploaded", null: false
    t.integer "parse_result_status", default: 0, null: false
    t.boolean "import_called", default: false
    t.text "failed_state_reason"
    t.text "parse_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_hash"], name: "index_document_data_on_document_hash", unique: true
    t.check_constraint "parse_state::text = ANY (ARRAY['uploaded'::character varying, 'queued'::character varying, 'processing'::character varying, 'parsed'::character varying, 'imported'::character varying, 'failed'::character varying]::text[])", name: "check_state"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "document_data_id", null: false
    t.string "original_filename", null: false
    t.string "stored_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_data_id"], name: "index_documents_on_document_data_id"
    t.index ["stored_name"], name: "index_documents_on_stored_name", unique: true
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "documents", "document_data", column: "document_data_id"
  add_foreign_key "documents", "users"
end
