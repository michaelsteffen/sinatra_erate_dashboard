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

ActiveRecord::Schema.define(version: 20140225021203) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "connections", force: true do |t|
    t.text     "frn"
    t.text     "f471_application_number"
    t.text     "ben"
    t.text     "applicant_name"
    t.text     "type_of_connections"
    t.integer  "number_of_lines"
    t.decimal  "download_speed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "connections", ["frn"], name: "index_connections_on_frn", using: :btree

  create_table "funding_requests", force: true do |t|
    t.text     "f471_application_number"
    t.text     "f471_form_status"
    t.text     "frn"
    t.text     "f470_application_number"
    t.text     "f470_form_status"
    t.text     "applicant_name"
    t.text     "ben"
    t.text     "application_type"
    t.text     "applicant_street_address1"
    t.text     "applicant_street_address2"
    t.text     "applicant_city"
    t.text     "applicant_state"
    t.text     "applicant_zip_code"
    t.text     "spin"
    t.text     "service_provider_name"
    t.text     "commitment_status"
    t.text     "fcdl_comment"
    t.text     "f486_ssd"
    t.integer  "funding_year"
    t.date     "fcdl_date"
    t.date     "contract_exp_date"
    t.date     "last_date_to_invoice"
    t.text     "orig_category_of_service"
    t.decimal  "orig_r_monthly_cost",                 precision: 20, scale: 6
    t.decimal  "orig_r_ineligible_cost",              precision: 20, scale: 6
    t.decimal  "orig_r_eligible_cost",                precision: 20, scale: 6
    t.integer  "orig_r_months_of_service"
    t.decimal  "orig_r_annual_cost",                  precision: 20, scale: 6
    t.decimal  "orig_nr_cost",                        precision: 20, scale: 6
    t.decimal  "orig_nr_ineligible_cost",             precision: 20, scale: 6
    t.decimal  "orig_nr_eligible_cost",               precision: 20, scale: 6
    t.decimal  "orig_total_cost",                     precision: 20, scale: 6
    t.decimal  "orig_discount",                       precision: 9,  scale: 6
    t.decimal  "orig_commitment_request",             precision: 20, scale: 6
    t.text     "cmtd_category_of_service"
    t.decimal  "committed_amount",                    precision: 20, scale: 6
    t.decimal  "cmtd_r_monthly_cost",                 precision: 20, scale: 6
    t.decimal  "cmtd_r_ineligible_cost",              precision: 20, scale: 6
    t.decimal  "cmtd_r_eligible_cost",                precision: 20, scale: 6
    t.integer  "cmtd_r_months_of_service"
    t.decimal  "cmtd_r_annual_cost",                  precision: 20, scale: 6
    t.decimal  "cmtd_nr_cost",                        precision: 20, scale: 6
    t.decimal  "cmtd_nr_ineligible_cost",             precision: 20, scale: 6
    t.decimal  "cmtd_nr_eligible_cost",               precision: 20, scale: 6
    t.decimal  "cmtd_total_cost",                     precision: 20, scale: 6
    t.decimal  "cmtd_discount",                       precision: 9,  scale: 6
    t.decimal  "cmtd_commitment_request",             precision: 20, scale: 6
    t.text     "cmtd_471_ssd"
    t.text     "invoicing_mode"
    t.text     "site_identifier"
    t.decimal  "total_authorized_disbursement",       precision: 20, scale: 6
    t.text     "wave_number"
    t.text     "appeal_wave_number"
    t.boolean  "does_not_provide_broadband"
    t.decimal  "pct_classrooms_with_wireless_access", precision: 7,  scale: 4
    t.decimal  "pct_classrooms_with_wired_access",    precision: 7,  scale: 4
    t.boolean  "last_mile_connections"
    t.boolean  "backbone_only"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "funding_requests", ["frn"], name: "index_funding_requests_on_frn", unique: true, using: :btree

end
