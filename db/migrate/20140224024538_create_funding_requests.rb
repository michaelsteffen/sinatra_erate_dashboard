class CreateFundingRequests < ActiveRecord::Migration
   def change
      create_table :funding_requests do |t|
        t.text :f471_application_number, :f471_form_status, :frn 
        t.text :f470_application_number, :f470_form_status, :applicant_name
        t.text :ben, :application_type, :applicant_street_address1
        t.text :applicant_street_address2, :applicant_city, :applicant_state
		t.text :applicant_zip_code, :spin, :service_provider_name, :commitment_status
		t.text :fcdl_comment, :f486_ssd
		t.integer :funding_year
  		t.date :fcdl_date, :contract_exp_date, :last_date_to_invoice
		t.text :orig_category_of_service
		t.decimal :orig_r_monthly_cost, :precision => 20, :scale => 6
		t.decimal :orig_r_ineligible_cost, :precision => 20, :scale => 6
		t.decimal :orig_r_eligible_cost, :precision => 20, :scale => 6
		t.integer :orig_r_months_of_service
		t.decimal :orig_r_annual_cost, :precision => 20, :scale => 6
		t.decimal :orig_nr_cost, :precision => 20, :scale => 6
		t.decimal :orig_nr_ineligible_cost, :precision => 20, :scale => 6
		t.decimal :orig_nr_eligible_cost, :precision => 20, :scale => 6
		t.decimal :orig_total_cost, :precision => 20, :scale => 6
		t.decimal :orig_discount, :precision => 9, :scale => 6
		t.decimal :orig_commitment_request, :precision => 20, :scale => 6
		t.text :cmtd_category_of_service
		t.decimal :committed_amount, :precision => 20, :scale => 6 
		t.decimal :cmtd_r_monthly_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_r_ineligible_cost, :precision => 20, :scale => 6
 		t.decimal :cmtd_r_eligible_cost, :precision => 20, :scale => 6
 		t.integer :cmtd_r_months_of_service
 		t.decimal :cmtd_r_annual_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_nr_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_nr_ineligible_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_nr_eligible_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_total_cost, :precision => 20, :scale => 6
		t.decimal :cmtd_discount, :precision => 9, :scale => 6
		t.decimal :cmtd_commitment_request, :precision => 20, :scale => 6
		t.text :cmtd_471_ssd, :invoicing_mode, :site_identifier	
		t.decimal :total_authorized_disbursement, :precision => 20, :scale => 6
		t.text :wave_number, :appeal_wave_number
		t.boolean :does_not_provide_broadband 
		t.decimal :pct_classrooms_with_wireless_access, :precision => 7, :scale => 4
		t.decimal :pct_classrooms_with_wired_access, :precision => 7, :scale => 4
		t.boolean :last_mile_connections, :backbone_only
        
        t.timestamps   
      end
      
      add_index :funding_requests, :frn, :unique => true
   end
end
