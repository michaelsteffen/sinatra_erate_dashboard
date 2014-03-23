class ApplicantDashboardPresenter
  @@queries = {}
  attr_reader :num_applications, :num_applicants, :app_types 

  def initialize(init_type = :full)
	self.initialize_query_strings

	if init_type == :zero
	elsif init_type == :small 
		@num_applicants = FundingRequest.connection.select_all(@@queries[:count_applicants_query])[0]["count"]
	else
		@num_applications = FundingRequest.connection.select_all(@@queries[:count_apps_query])[0]["count"]
		@num_applicants = FundingRequest.connection.select_all(@@queries[:count_applicants_query])[0]["count"]

		@app_types = FundingRequest.connection.select_all(@@queries[:app_type_stats_query])
	end
  end
  
  def initialize_query_strings
  	@@queries[:count_apps_query] = <<-endquery
  		SELECT COUNT(*) 
		FROM (	SELECT DISTINCT f471_application_number
				FROM funding_requests
				WHERE f471_form_status = 'CERTIFIED' ) AS t1;
		endquery
		
	@@queries[:count_applicants_query] = <<-endquery	
		SELECT COUNT(*) 
		FROM ( SELECT DISTINCT ben
			   FROM funding_requests
			   WHERE f471_form_status = 'CERTIFIED') AS t1; 
		endquery
	
	@@queries[:app_type_stats_query] = <<-endquery
  		SELECT application_type, 
  			COUNT(DISTINCT f471_application_number) AS applications,
  			COUNT(DISTINCT ben) AS applicants
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED'
		GROUP BY application_type
		ORDER BY application_type;
		endquery
  end
end