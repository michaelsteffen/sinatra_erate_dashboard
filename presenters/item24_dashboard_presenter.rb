class Item24DashboardPresenter
  @@queries = {}
  attr_reader :item24_requests, :percent_of_p1, :requests_by_type, :multiple_types
  attr_reader :requests_by_speed, :multiple_speed, :speed_tier_names, :multiple_speeds
  
  def initialize
	self.initialize_query_strings

  	@item24_requests = FundingRequest.connection.select_all(@@queries[:item24_requests_query])[0]["sum"]
  	@percent_of_p1 = @item24_requests.to_f / FundingRequest.connection.select_all(@@queries[:total_requests_query])[0]["sum"].to_f
   	
   	@requests_by_type = FundingRequest.connection.select_all(@@queries[:requests_by_type_query])
   	@multiple_types = FundingRequest.connection.select_all(@@queries[:multiple_types_query])[0]["sum"]

   	@requests_by_speed = FundingRequest.connection.select_all(@@queries[:requests_by_speed_query])
    @multiple_speeds = FundingRequest.connection.select_all(@@queries[:multiple_speed_query])[0]["sum"]

	@speed_tier_names = { '1' => '< 1.5 Mbps', '2' => '1.5 - 9 Mbps', '3' => '10 - 99 Mbps', 
						  '4' => '100 - 999 Mbps', '5' => '1 - 9.9 Gbps', '6' => '10+ Gbps'} 
  end
  
  def initialize_query_strings
  	@@queries[:item24_requests_query] = <<-endquery
  		SELECT SUM(funding_requests.orig_commitment_request) 
		FROM ( SELECT DISTINCT frn 
			   FROM connections
			   WHERE type_of_connections != 'Cellular Wireless') AS t1 
			   LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE f471_form_status = 'CERTIFIED';
		endquery

  	@@queries[:total_requests_query] = <<-endquery
		SELECT SUM(orig_commitment_request) 
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED';
		endquery
		
	@@queries[:requests_by_type_query] = <<-endquery
		CREATE TEMPORARY TABLE frn_num_connection_types ON COMMIT DROP AS
		SELECT frn, COUNT(*) AS count_types
		FROM ( SELECT DISTINCT frn, type_of_connections
			   FROM connections ) as t1
		GROUP BY frn;

		SELECT type_of_connections, SUM(funding_requests.orig_commitment_request) 
		FROM ( SELECT DISTINCT frn, type_of_connections
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_connection_types WHERE count_types = 1) AND
				type_of_connections != 'Cellular Wireless' ) AS t1 
			   LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED'
		GROUP BY type_of_connections
		ORDER BY SUM(funding_requests.orig_commitment_request) DESC;
		endquery

	@@queries[:multiple_types_query] = <<-endquery
		CREATE TEMPORARY TABLE frn_num_connection_types ON COMMIT DROP AS
		SELECT frn, COUNT(*) AS count_types
		FROM ( SELECT DISTINCT frn, type_of_connections
			   FROM connections ) as t1
		GROUP BY frn;
	
		SELECT SUM(funding_requests.orig_commitment_request) 
		FROM ( SELECT DISTINCT frn
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_connection_types WHERE count_types > 1) ) AS t1 
		LEFT JOIN funding_requests
		ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED';
		endquery
	
	@@queries[:requests_by_speed_query] = <<-endquery
		CREATE TEMPORARY TABLE frn_num_speeds ON COMMIT DROP AS
		SELECT frn, COUNT(*) AS count_speeds
		FROM ( SELECT DISTINCT frn, download_speed
			   FROM connections ) as t1
		GROUP BY frn;

		SELECT t1.speed_tier, SUM(funding_requests.orig_commitment_request) 
		FROM ( SELECT DISTINCT frn, 
			   CASE WHEN download_speed < 1.5 THEN 1 
			   		WHEN 1.5 <= download_speed AND download_speed < 10 THEN 2 
			   		WHEN 10 <= download_speed AND download_speed < 100 THEN 3 
			   		WHEN 100 <= download_speed AND download_speed < 1000 THEN 4 
			   		WHEN 1000 <= download_speed AND download_speed < 10000 THEN 5 
					WHEN 10000 <= download_speed THEN 6
			   END AS speed_tier
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_speeds WHERE count_speeds = 1) AND 
			    type_of_connections != 'Cellular Wireless' ) AS t1 
			   LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED'
		GROUP BY t1.speed_tier
		ORDER BY t1.speed_tier ASC;
		endquery
		
	@@queries[:multiple_speed_query] = <<-endquery
		CREATE TEMPORARY TABLE frn_num_speeds ON COMMIT DROP AS
		SELECT frn, COUNT(*) AS count_speeds
		FROM ( SELECT DISTINCT frn, download_speed
			   FROM connections ) as t1
		GROUP BY frn;

		SELECT SUM(funding_requests.orig_commitment_request) 
		FROM ( SELECT DISTINCT frn
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_speeds WHERE count_speeds > 1) AND
				type_of_connections != 'Cellular Wireless' ) AS t1 
		LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED';
		endquery
  end
end