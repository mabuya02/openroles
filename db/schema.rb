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

ActiveRecord::Schema[8.0].define(version: 2025_09_01_204413) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alerts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.jsonb "criteria", default: {}
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "frequency", default: "daily"
    t.datetime "last_notified_at"
    t.string "unsubscribe_token"
    t.index ["frequency"], name: "index_alerts_on_frequency"
    t.index ["last_notified_at"], name: "index_alerts_on_last_notified_at"
    t.index ["unsubscribe_token"], name: "index_alerts_on_unsubscribe_token", unique: true
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "alerts_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "alert_id", null: false
    t.uuid "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_id", "tag_id"], name: "index_alerts_tags_on_alert_id_and_tag_id", unique: true
    t.index ["alert_id"], name: "index_alerts_tags_on_alert_id"
    t.index ["tag_id"], name: "index_alerts_tags_on_tag_id"
  end

  create_table "applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "job_id", null: false
    t.uuid "resume_id"
    t.text "cover_letter"
    t.string "status", default: "applied", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["job_id"], name: "index_applications_on_job_id"
    t.index ["resume_id"], name: "index_applications_on_resume_id"
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "website"
    t.string "industry"
    t.string "location"
    t.string "logo_url"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "slug"
    t.index ["name"], name: "index_companies_on_name", unique: true
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "job_metadata", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.string "meta_title"
    t.text "meta_description"
    t.string "meta_keywords"
    t.string "slug"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.string "og_image_url"
    t.string "twitter_card_type"
    t.json "schema_markup"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["job_id"], name: "index_job_metadata_on_job_id", unique: true
  end

  create_table "job_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.uuid "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_job_tags_on_job_id"
    t.index ["tag_id"], name: "index_job_tags_on_tag_id"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "title"
    t.text "description"
    t.string "location"
    t.string "employment_type"
    t.decimal "salary"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "external_id"
    t.string "source"
    t.string "fingerprint"
    t.datetime "posted_at"
    t.string "apply_url"
    t.jsonb "raw_payload", default: {}
    t.decimal "salary_min", precision: 12, scale: 2
    t.decimal "salary_max", precision: 12, scale: 2
    t.tsvector "search_vector"
    t.string "currency", default: "USD", null: false
    t.index ["company_id"], name: "index_jobs_on_company_id"
    t.index ["description"], name: "index_jobs_on_description_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["fingerprint"], name: "index_jobs_on_fingerprint", unique: true, where: "(fingerprint IS NOT NULL)"
    t.index ["location"], name: "index_jobs_on_location_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["posted_at"], name: "index_jobs_on_posted_at"
    t.index ["salary_min", "salary_max"], name: "index_jobs_on_salary_min_and_salary_max"
    t.index ["search_vector"], name: "index_jobs_on_search_vector", using: :gin
    t.index ["source", "external_id"], name: "index_jobs_on_source_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["title"], name: "index_jobs_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "password_reset_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.boolean "used", default: false
    t.datetime "used_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_password_reset_tokens_on_email"
    t.index ["expires_at"], name: "index_password_reset_tokens_on_expires_at"
    t.index ["token", "used"], name: "index_password_reset_tokens_on_token_and_used"
    t.index ["token"], name: "index_password_reset_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
  end

  create_table "saved_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "job_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["job_id"], name: "index_saved_jobs_on_job_id"
    t.index ["user_id"], name: "index_saved_jobs_on_user_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "portfolio_url"
    t.string "linkedin_url"
    t.string "github_url"
    t.text "bio"
    t.string "skills"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.string "phone_number"
    t.string "status", default: "inactive", null: false
    t.boolean "email_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "password_digest"
    t.string "company"
    t.text "bio"
    t.string "avatar_url"
    t.boolean "two_factor_enabled"
    t.string "two_factor_secret"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "confirmed_at"
    t.boolean "phone_verified", default: false, null: false
    t.boolean "admin", default: false, null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_sign_in_at"], name: "index_users_on_last_sign_in_at"
  end

  create_table "verification_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "code", null: false
    t.string "code_type", null: false
    t.string "contact_method"
    t.datetime "expires_at", null: false
    t.boolean "verified", default: false
    t.datetime "verified_at"
    t.integer "attempts", default: 0
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "code_type"], name: "index_verification_codes_on_code_and_code_type", unique: true
    t.index ["expires_at"], name: "index_verification_codes_on_expires_at"
    t.index ["user_id", "code_type"], name: "index_verification_codes_on_user_id_and_code_type"
    t.index ["user_id"], name: "index_verification_codes_on_user_id"
    t.index ["verified"], name: "index_verification_codes_on_verified"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alerts", "users"
  add_foreign_key "alerts_tags", "alerts"
  add_foreign_key "alerts_tags", "tags"
  add_foreign_key "applications", "jobs"
  add_foreign_key "applications", "user_profiles", column: "resume_id"
  add_foreign_key "applications", "users"
  add_foreign_key "job_metadata", "jobs"
  add_foreign_key "job_tags", "jobs"
  add_foreign_key "job_tags", "tags"
  add_foreign_key "jobs", "companies"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "saved_jobs", "jobs"
  add_foreign_key "saved_jobs", "users"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "verification_codes", "users"
end
