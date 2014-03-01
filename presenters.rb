class BasicDashboardPresenter
  @@queries = {}
  attr_reader :num_applications

  def initialize
	self.initialize_query_strings

  	@num_applications = FundingRequest.connection.select_all(@@queries[:num_apps_query])[0]["count"]
  end
  
  def initialize_query_strings
  	@@queries[:num_apps_query] = <<-endquery
  		SELECT COUNT(*) 
		FROM (	SELECT DISTINCT f471_application_number
				FROM funding_requests
				WHERE f471_form_status = 'CERTIFIED' ) AS t1;
		endquery
  end
end