class ProcessingDashboardPresenter
  @@queries = {}
  @@broadband_def = "download_speed >= 50 AND type_of_connections != 'Cellular Wireless'"
  
  attr_reader :days_since_window_close, :days_to_labor_day
  attr_reader :processing_metrics, :processing_denominators, :avg_processing_time  

  def initialize(init_type = :full)
	self.initialize_query_strings

	if init_type == :zero
	elsif init_type == :small 
		@processing_metrics = {}
		@processing_metrics["lines"] = 
			FundingRequest.connection.select_all(@@queries[:processed_lines_query])[0]["sum"].to_f / 
			Connection.where(@@broadband_def).sum(:number_of_lines)
	else
		@processing_metrics = {}
		@processing_denominators = {}
		
		@processing_denominators["lines"] = 
			FundingRequest.connection.select_all(@@queries[:all_lines_query])[0]["sum"].to_f
		@processing_metrics["lines"] = 
			FundingRequest.connection.select_all(@@queries[:processed_lines_query])[0]["sum"].to_f / 
			@processing_denominators["lines"]

		@processing_denominators["bband_dollars"] = 
			FundingRequest.connection.select_all(@@queries[:all_bband_dollars_query])[0]["sum"].to_f
		@processing_metrics["bband_dollars"] = 
			FundingRequest.connection.select_all(@@queries[:processed_bband_dollars_query])[0]["sum"].to_f / 
			@processing_denominators["bband_dollars"] 	
			
		@processing_denominators["dollars"] = 
			FundingRequest.where("funding_requests.f471_form_status = 'CERTIFIED'") \
				.sum(:orig_commitment_request).to_f
		@processing_metrics["dollars"] = 
			FundingRequest.where("commitment_status IS NOT NULL AND funding_requests.f471_form_status = 'CERTIFIED'") \
				.sum(:orig_commitment_request).to_f / 
			@processing_denominators["dollars"] 
		
		@processing_denominators["apps"] = 
			FundingRequest.select(:f471_application_number) \
				.where("funding_requests.f471_form_status = 'CERTIFIED'") \
				.distinct.count.to_f
		@processing_metrics["apps"] = 
			FundingRequest.select(:f471_application_number) \
				.where("commitment_status IS NOT NULL AND funding_requests.f471_form_status = 'CERTIFIED'") \
				.distinct.count.to_f / 
			@processing_denominators["apps"] 		
	end
  end
  
  def initialize_query_strings
  	@@queries[:processed_lines_query] = <<-endquery
		SELECT SUM(number_of_lines) 
		FROM connections LEFT JOIN funding_requests ON connections.frn = funding_requests.frn
		WHERE commitment_status IS NOT NULL 
			AND #{@@broadband_def} 
			AND funding_requests.f471_form_status = 'CERTIFIED';
		endquery

  	@@queries[:all_lines_query] = <<-endquery
		SELECT SUM(number_of_lines) 
		FROM connections LEFT JOIN funding_requests ON connections.frn = funding_requests.frn
		WHERE #{@@broadband_def} 
			AND funding_requests.f471_form_status = 'CERTIFIED';
		endquery
	
	@@queries[:processed_bband_dollars_query] = <<-endquery
		WITH processed_high_speed_frns AS (
			SELECT DISTINCT funding_requests.frn
			FROM connections LEFT JOIN funding_requests ON connections.frn = funding_requests.frn
			WHERE commitment_status IS NOT NULL 
				AND #{@@broadband_def} 
				AND funding_requests.f471_form_status = 'CERTIFIED')
			
		SELECT SUM(orig_commitment_request)
		FROM funding_requests
		WHERE frn IN (SELECT frn FROM processed_high_speed_frns);
		endquery
		
	@@queries[:all_bband_dollars_query] = <<-endquery
		WITH all_high_speed_frns AS (
			SELECT DISTINCT funding_requests.frn
			FROM connections LEFT JOIN funding_requests ON connections.frn = funding_requests.frn
			WHERE #{@@broadband_def} AND funding_requests.f471_form_status = 'CERTIFIED' )
			
		SELECT SUM(orig_commitment_request)
		FROM funding_requests
		WHERE frn IN (SELECT frn FROM all_high_speed_frns);
		endquery
  end
end