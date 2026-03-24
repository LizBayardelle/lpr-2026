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

ActiveRecord::Schema[8.1].define(version: 2026_03_24_162751) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blogs", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "published", default: false
    t.datetime "published_at"
    t.string "teaser"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_blogs_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "slug"
    t.integer "sort"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "category_blogs", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_category_blogs_on_blog_id"
    t.index ["category_id"], name: "index_category_blogs_on_category_id"
  end

  create_table "client_uploads", force: :cascade do |t|
    t.datetime "assigned_at"
    t.bigint "assigned_by_user_id"
    t.string "client_email", null: false
    t.string "client_name", null: false
    t.string "client_phone"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "document_type", null: false
    t.bigint "loan_id"
    t.string "name"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_client_uploads_on_loan_id"
    t.index ["status"], name: "index_client_uploads_on_status"
  end

  create_table "contact_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "status", default: "new", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_contact_submissions_on_status"
  end

  create_table "loan_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "document_type", null: false
    t.bigint "loan_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uploaded_by_name"
    t.bigint "uploaded_by_user_id"
    t.index ["loan_id"], name: "index_loan_documents_on_loan_id"
    t.index ["uploaded_by_user_id"], name: "index_loan_documents_on_uploaded_by_user_id"
  end

  create_table "loan_draws", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.date "draw_date", null: false
    t.text "inspection_notes"
    t.bigint "loan_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_draws_on_loan_id"
  end

  create_table "loan_extensions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "extension_fee", precision: 12, scale: 2, default: "0.0"
    t.bigint "loan_id", null: false
    t.date "new_maturity_date", null: false
    t.decimal "new_rate", precision: 5, scale: 3
    t.text "notes"
    t.date "original_maturity_date", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_extensions_on_loan_id"
  end

  create_table "loan_fees", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.date "fee_date", null: false
    t.string "fee_type", null: false
    t.bigint "loan_id", null: false
    t.boolean "paid", default: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_fees_on_loan_id"
  end

  create_table "loan_ledger_entries", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.date "effective_date", null: false
    t.string "entry_type", null: false
    t.bigint "loan_id", null: false
    t.jsonb "metadata", default: {}
    t.bigint "posted_by_id"
    t.bigint "reversal_of_id"
    t.bigint "reversed_by_id"
    t.decimal "running_balance", precision: 12, scale: 2, null: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.index ["loan_id", "effective_date", "id"], name: "index_loan_ledger_entries_on_loan_id_and_effective_date_and_id"
    t.index ["loan_id"], name: "index_loan_ledger_entries_on_loan_id"
    t.index ["posted_by_id"], name: "index_loan_ledger_entries_on_posted_by_id"
    t.index ["reversal_of_id"], name: "index_loan_ledger_entries_on_reversal_of_id"
    t.index ["source_type", "source_id"], name: "index_loan_ledger_entries_on_source_type_and_source_id"
  end

  create_table "loan_reserves", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "established_date", null: false
    t.bigint "loan_id", null: false
    t.text "notes"
    t.string "reserve_type", default: "interest", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_reserves_on_loan_id"
    t.index ["source_type", "source_id"], name: "index_loan_reserves_on_source"
  end

  create_table "loan_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["loan_id"], name: "index_loan_roles_on_loan_id"
    t.index ["user_id", "loan_id", "role"], name: "index_loan_roles_on_user_id_and_loan_id_and_role", unique: true
    t.index ["user_id"], name: "index_loan_roles_on_user_id"
  end

  create_table "loan_statements", force: :cascade do |t|
    t.decimal "beginning_balance", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "ending_balance", precision: 12, scale: 2, null: false
    t.decimal "interest_due", precision: 12, scale: 2, null: false
    t.decimal "late_fee", precision: 12, scale: 2, default: "0.0"
    t.bigint "loan_id", null: false
    t.text "notes"
    t.decimal "past_due_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "payments_received", precision: 12, scale: 2, default: "0.0"
    t.date "period_end", null: false
    t.date "period_start", null: false
    t.decimal "principal_due", precision: 12, scale: 2, default: "0.0"
    t.date "statement_date", null: false
    t.decimal "total_due", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id", "statement_date"], name: "index_loan_statements_on_loan_id_and_statement_date"
    t.index ["loan_id"], name: "index_loan_statements_on_loan_id"
    t.index ["statement_date"], name: "index_loan_statements_on_statement_date"
  end

  create_table "loans", force: :cascade do |t|
    t.text "borrower_address"
    t.string "borrower_email"
    t.string "borrower_name", null: false
    t.string "borrower_phone"
    t.datetime "created_at", null: false
    t.decimal "default_interest_rate", precision: 5, scale: 3
    t.date "first_payment_date"
    t.integer "grace_period_days", default: 10
    t.string "interest_calc_method", default: "30_360"
    t.decimal "interest_rate", precision: 5, scale: 3, null: false
    t.decimal "late_fee_percent", precision: 5, scale: 3, default: "5.0"
    t.decimal "loan_amount", precision: 12, scale: 2, null: false
    t.integer "loan_term_months", null: false
    t.date "maturity_date", null: false
    t.text "notes"
    t.date "origination_date", null: false
    t.decimal "origination_fee_flat", precision: 12, scale: 2
    t.string "origination_fee_handling", default: "net_funded", null: false
    t.decimal "origination_fee_percent", precision: 5, scale: 3, default: "0.0"
    t.string "origination_fee_type", default: "percent", null: false
    t.string "payment_type", default: "interest_only"
    t.string "property_address", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["borrower_name"], name: "index_loans_on_borrower_name"
    t.index ["maturity_date"], name: "index_loans_on_maturity_date"
    t.index ["status"], name: "index_loans_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "extra_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "interest_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "late_fee_amount", precision: 12, scale: 2, default: "0.0"
    t.bigint "loan_id", null: false
    t.bigint "loan_reserve_id"
    t.text "notes"
    t.date "payment_date", null: false
    t.string "payment_method"
    t.decimal "principal_amount", precision: 12, scale: 2, default: "0.0"
    t.string "reference_number"
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_payments_on_loan_id"
    t.index ["loan_reserve_id"], name: "index_payments_on_loan_reserve_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
  end

  create_table "statement_sends", force: :cascade do |t|
    t.string "cc_to"
    t.datetime "created_at", null: false
    t.bigint "loan_statement_id", null: false
    t.bigint "sent_by_id", null: false
    t.string "sent_to", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_statement_id"], name: "index_statement_sends_on_loan_statement_id"
    t.index ["sent_by_id"], name: "index_statement_sends_on_sent_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.boolean "godpowers", default: false, null: false
    t.string "last_name"
    t.text "notes"
    t.string "phone_number"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "welcome_email_sends", force: :cascade do |t|
    t.string "cc_to"
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.bigint "sent_by_id", null: false
    t.string "sent_to", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_welcome_email_sends_on_loan_id"
    t.index ["sent_by_id"], name: "index_welcome_email_sends_on_sent_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blogs", "users"
  add_foreign_key "category_blogs", "blogs"
  add_foreign_key "category_blogs", "categories"
  add_foreign_key "client_uploads", "loans"
  add_foreign_key "client_uploads", "users", column: "assigned_by_user_id"
  add_foreign_key "loan_documents", "loans"
  add_foreign_key "loan_documents", "users", column: "uploaded_by_user_id"
  add_foreign_key "loan_draws", "loans"
  add_foreign_key "loan_extensions", "loans"
  add_foreign_key "loan_fees", "loans"
  add_foreign_key "loan_ledger_entries", "loans"
  add_foreign_key "loan_ledger_entries", "users", column: "posted_by_id"
  add_foreign_key "loan_reserves", "loans"
  add_foreign_key "loan_roles", "loans"
  add_foreign_key "loan_roles", "users"
  add_foreign_key "loan_statements", "loans"
  add_foreign_key "payments", "loan_reserves"
  add_foreign_key "payments", "loans"
  add_foreign_key "statement_sends", "loan_statements"
  add_foreign_key "statement_sends", "users", column: "sent_by_id"
  add_foreign_key "welcome_email_sends", "loans"
  add_foreign_key "welcome_email_sends", "users", column: "sent_by_id"
end
