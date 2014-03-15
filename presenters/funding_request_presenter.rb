class FundingRequestPresenter
  attr_reader :type, :priority, :appno
  attr_reader :sort_long_names, :sort_code, :page_len_options, :page_len, :page
  attr_reader :requests, :request_count  
  
  def initialize(type, discount, appno, ben, priority, sort, page_len, page)
    @type = type || nil
    @appno = appno || nil
    @ben = ben || nil
    @priority = ["p1","p2"].include?(priority) ? priority : "all"

    where_query_str = []
    where_query_hash = {}
    (where_query_str << "application_type = :type"; where_query_hash[:type] = @type) unless @type.nil?
    if discount
		where_query_str << "orig_discount >= :band_low AND orig_discount < :band_high"
		where_query_hash[:band_low] = discount.to_i
		where_query_hash[:band_high] = discount.to_i + 10
	end
    (where_query_str << "f471_application_number = :appno"; where_query_hash[:appno] = @appno) unless @appno.nil?
    (where_query_str << "ben = :ben"; where_query_hash[:ben] = @ben) unless @ben.nil?
    where_query_str << "orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS')" if @priority == 'p1'
    where_query_str << "orig_category_of_service IN ('INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT')" if @priority == 'p2'
    where_query_str << "f471_form_status = 'CERTIFIED'"
	where_query = [where_query_str.join(" AND "), where_query_hash]

  	@sort_long_names = {"appno" => "Application Number", 
  						"frn" => "FRN", 
  						"ben" => "BEN", 
  						"name" => "Applicant Name", 
  						"request" => "Requested Support"}
  	sort_query = {"appno" => "f471_application_number ASC", 
  				  "frn" => "frn ASC", 
  				  "ben" => "ben ASC", 
  				  "name" => "applicant_name ASC", 
  				  "request" => "orig_commitment_request DESC"} 
  				  
  	@sort_code = @sort_long_names.has_key?(sort) ? sort : "frn"
  	
  	@page_len_options = [100, 500, 1000, 5000]
  	@page_len = Integer(page_len) rescue 500
  	@page = Integer(page) rescue 1
  	
	@requests = FundingRequest.where(where_query).order(sort_query[@sort_code]) \
					.limit(@page_len).offset((@page-1)*@page_len)
	@request_count = FundingRequest.where(where_query).count
  end
end