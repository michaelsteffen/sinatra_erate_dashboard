class BasicDashboardPresenter
  @@queries = {}
  attr_reader :num_applications, :application_count_by_type, :num_applicants, :applicant_count_by_apptype 
  attr_reader :requested_funding, :requests_by_apptype, :requests_by_discount, :prediscount_costs, :avg_discount

  def initialize
	self.initialize_query_strings

  	@num_applications = FundingRequest.connection.select_all(@@queries[:count_apps_query])[0]["count"]
  	@application_count_by_type = FundingRequest.connection.select_all(@@queries[:apps_by_type_query])
  	@num_applicants = FundingRequest.connection.select_all(@@queries[:count_applicants_query])[0]["count"]
  	@applicant_count_by_apptype = FundingRequest.connection.select_all(@@queries[:applicants_by_apptype_query])
  	
  	@requested_funding = {}
  	@requested_funding["all"] = FundingRequest.connection.select_all(@@queries[:requested_funding_query])[0]["total_request"]
  	@requested_funding["p1"] = FundingRequest.connection.select_all(@@queries[:requested_funding_query])[0]["p1_request"]
  	@requested_funding["p2"] = FundingRequest.connection.select_all(@@queries[:requested_funding_query])[0]["p2_request"]
  	
  	@requests_by_apptype = FundingRequest.connection.select_all(@@queries[:requests_by_apptype_query])
  	@requests_by_discount = FundingRequest.connection.select_all(@@queries[:requests_by_discount_query])
  	
  	@prediscount_costs = {}
  	@prediscount_costs["all"] = FundingRequest.connection.select_all(@@queries[:prediscount_costs_query])[0]["total_costs"]
   	@prediscount_costs["p1"] = FundingRequest.connection.select_all(@@queries[:prediscount_costs_query])[0]["p1_costs"]
   	@prediscount_costs["p2"] = FundingRequest.connection.select_all(@@queries[:prediscount_costs_query])[0]["p2_costs"]	
   	
   	@avg_discount = {}
   	@avg_discount["all"] = @requested_funding["all"].to_f / @prediscount_costs["all"].to_f
   	@avg_discount["p1"] = @requested_funding["p1"].to_f / @prediscount_costs["p1"].to_f
   	@avg_discount["p2"] = @requested_funding["p2"].to_f / @prediscount_costs["p2"].to_f	

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
	
	@@queries[:requested_funding_query] = <<-endquery	
		SELECT 
			SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_commitment_request END) AS p1_request,
			SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_commitment_request END) AS p2_request,
			SUM(orig_commitment_request) AS total_request
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED';
		endquery

	@@queries[:requests_by_apptype_query] = <<-endquery			
		SELECT application_type,
			SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_commitment_request END) AS p1_request,
			SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_commitment_request END) AS p2_request,
			SUM(orig_commitment_request) AS total_request
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED'
		GROUP BY application_type
		ORDER BY application_type;
		endquery

	@@queries[:requests_by_discount_query] = <<-endquery					
		SELECT 
			TRUNC(orig_discount/10.) * 10. AS discount_band,
			SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_commitment_request END) AS p1_request,
			SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_commitment_request END) AS p2_request,
			SUM(orig_commitment_request) AS total_request
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED'
		GROUP BY discount_band
		ORDER BY discount_band;
		endquery

	@@queries[:prediscount_costs_query] = <<-endquery					
		SELECT 
			SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_total_cost END) AS p1_costs,
			SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_total_cost END) AS p2_costs,
			SUM(orig_total_cost) AS total_costs
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED';
		endquery
  end
end