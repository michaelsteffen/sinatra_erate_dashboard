class ApplicationPresenter
  attr_reader :applications, :application_count
  
  def initialize(type, sort, page)	
	@applications = FundingRequest.select(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state, "sum(orig_commitment_request) as total_req") \
		.where(:application_type => type) \
		.group(:f471_application_number, :funding_year, :application_type, :ben, :applicant_name, :applicant_state) \
		.order("sum(orig_commitment_request) DESC") \
		.limit(1000).offset((page-1)*1000)
	@application_count = FundingRequest.select(:f471_application_number).where(:application_type => type).distinct.count
  end
end