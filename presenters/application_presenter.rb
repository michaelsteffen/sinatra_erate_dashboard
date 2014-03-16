class ApplicationPresenter
  attr_reader :type, :sort_long_names, :sort_code, :page_len_options, :page_len, :page
  attr_reader :applications, :application_count  
  
  def initialize(params)	
    @type = params[:type] unless (params[:type] == "")
    
  	@sort_long_names = {"appno" => "Application Number", 
  						"ben" => "BEN", 
  						"name" => "Applicant Name", 
  						"request" => "Requested Support"}
  	sort_query = {"appno" => "f471_application_number ASC", 
  				  "ben" => "ben ASC", 
  				  "name" => "applicant_name ASC", 
  				  "request" => "sum(orig_commitment_request) DESC"}
  	@sort_code = @sort_long_names.has_key?(params[:sort]) ? params[:sort] : "request"
  	
  	where_query = {:f471_form_status => 'CERTIFIED'}
  	where_query[:application_type] = @type unless @type.nil?
  	
  	@page_len_options = [100, 500, 1000, 5000]
  	@page_len = Integer(params[:page_len]) rescue 500
  	@page = Integer(params[:page]) rescue 1
  	
	@applications = FundingRequest.select(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state, "sum(orig_commitment_request) as total_req") \
		.where(where_query) \
		.group(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state) \
		.order(sort_query[@sort_code]) \
		.limit(@page_len).offset((@page-1)*@page_len)
	@application_count = FundingRequest.select(:f471_application_number).where(where_query).distinct.count
  end
end