class ApplicationPresenter
  attr_reader :applications
  
  def initialize(*params)
	puts params
	
	@applications = FundingRequest.select(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state, "sum(orig_commitment_request) as total_req") \
		.where(:application_type => params[0][:type]) \
		.group(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state) \
		.order("sum(orig_commitment_request) DESC") \
		.limit(1000).offset(params[0][:page]*1000)
  end
end