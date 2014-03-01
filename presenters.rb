class BasicDashboardPresenter
  @@queries = {}
  attr_reader :num_applications, :application_count_by_type, :num_applicants, :applicant_count_by_apptype 

  def initialize
	self.initialize_query_strings

  	@num_applications = FundingRequest.connection.select_all(@@queries[:count_apps_query])[0]["count"]
  	@application_count_by_type = FundingRequest.connection.select_all(@@queries[:apps_by_type_query])
  	@num_applicants = FundingRequest.connection.select_all(@@queries[:count_applicants_query])[0]["count"]
  	@applicant_count_by_apptype = FundingRequest.connection.select_all(@@queries[:applicants_by_apptype_query])
  end
  
  def initialize_query_strings
  	@@queries[:count_apps_query] = <<-endquery
  		SELECT COUNT(*) 
		FROM (	SELECT DISTINCT f471_application_number
				FROM funding_requests
				WHERE f471_form_status = 'CERTIFIED' ) AS t1;
		endquery
		
	@@queries[:apps_by_type_query] = <<-endquery
  		SELECT application_type, COUNT(*) 
		FROM ( SELECT DISTINCT f471_application_number, application_type
			   FROM funding_requests
			   WHERE f471_form_status = 'CERTIFIED') AS t1 
		GROUP BY application_type
		ORDER BY application_type;
		endquery
		
	@@queries[:count_applicants_query] = <<-endquery	
		SELECT COUNT(*) 
		FROM ( SELECT DISTINCT ben
			   FROM funding_requests
			   WHERE f471_form_status = 'CERTIFIED') AS t1; 
		endquery
		
	@@queries[:applicants_by_apptype_query] = <<-endquery	
		SELECT application_type, COUNT(*) 
		FROM ( SELECT DISTINCT ben, application_type
			   FROM funding_requests
			   WHERE f471_form_status = 'CERTIFIED') AS t1 
		GROUP BY application_type
		ORDER BY application_type;
		endquery
  end
end