class ApplicantPresenter
  attr_reader :type, :sort_long_names, :sort_code, :page_len_options, :page_len, :page
  attr_reader :applicants, :applicant_count  
  
  def initialize(type, sort, page_len, page)	
    @type = type || 'DISTRICT'
    
  	@sort_long_names = {"ben" => "BEN", "name" => "Applicant Name", "p1request" => "P1 Requested Support", "p2request" => "P2 Requested Support"}
  	sort_query = {"ben" => "ben ASC", "name" => "applicant_name ASC", 
  				  "p1request" => "SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_commitment_request END) DESC NULLS LAST", 
  				  "p2request" => "SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_commitment_request END) DESC NULLS LAST" }
  	@sort_code = @sort_long_names.has_key?(sort) ? sort : "ben"
  	
  	@page_len_options = [100,500,1000,5000]
  	@page_len = Integer(page_len) rescue 500
  	@page = Integer(page) rescue 1
  	
	@applicants = FundingRequest.select(:funding_year, :application_type, :ben, :applicant_name, :applicant_state, \
				"SUM(CASE WHEN orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS') THEN orig_commitment_request END) AS p1_request", \
				"SUM(CASE WHEN orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT') THEN orig_commitment_request END) AS p2_request") \
		.where(:application_type => type) \
		.group(:funding_year, :application_type, :ben, :applicant_name, :applicant_state) \
		.order(sort_query[@sort_code]) \
		.limit(@page_len).offset((@page-1)*@page_len)
	@applicant_count = FundingRequest.select(:ben).where(:application_type => type).distinct.count
  end
end