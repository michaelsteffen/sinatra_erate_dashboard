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
		t.float :orig_r_monthly_cost, :orig_r_ineligible_cost, :orig_r_eligible_cost
		t.integer :orig_r_months_of_service
		t.float :orig_r_annual_cost, :orig_nr_cost, :orig_nr_ineligible_cost
		t.float :orig_nr_eligible_cost, :orig_total_cost
		t.float :orig_discount, :orig_commitment_request
		t.text :cmtd_category_of_service
		t.float :committed_amount, :cmtd_r_monthly_cost, :cmtd_r_ineligible_cost
 		t.float :cmtd_r_eligible_cost, :cmtd_r_months_of_service, :cmtd_r_annual_cost
		t.float :cmtd_nr_cost, :cmtd_nr_ineligible_cost, :cmtd_nr_eligible_cost
		t.float :cmtd_total_cost, :cmtd_discount, :cmtd_commitment_request
		t.text :cmtd_471_ssd, :invoicing_mode, :site_identifier	
		t.float :total_authorized_disbursement
		t.text :wave_number, :appeal_wave_number
		t.boolean :does_not_provide_broadband 
		t.float :pct_classrooms_with_wireless_access, :pct_classrooms_with_wired_access
		t.boolean :last_mile_connections, :backbone_only
        
        t.timestamps   
      end
      
      add_index :funding_requests, :frn, :unique => true
   end
end
