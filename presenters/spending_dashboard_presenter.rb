class SpendingDashboardPresenter
  @@queries = {}
  attr_reader :conn_types, :single_ctype_stats
  attr_reader :item24_requests, :percent_of_p1, :requests_by_type, :multiple_types
  attr_reader :requests_by_speed, :multiple_speed, :speed_tier_names, :multiple_speeds
  attr_reader :requested_funding, :requests_by_apptype, :requests_by_discount, :prediscount_costs, :avg_discount

  def initialize(init_type = :full)
	self.initialize_query_strings

	if init_type == :zero
	elsif init_type == :small
		single_ctype_frns = FundingRequest.connection.select_all(@@queries[:single_ctype_frns_query])	
		conn_type = '1 Gbps fiber'
		frns = single_ctype_frns.select { |frn| frn['speed_type_category'] == conn_type}
		conn_prices = []
		conn_lines = 0
		frns.each do |frn|
			# commented out line would calculate median of lines rather than median of requests
			# conn_prices.concat( Array.new(frn['number_of_lines'].to_i) {frn['orig_r_monthly_cost'].to_d/frn['number_of_lines'].to_d} )
			conn_prices << frn['orig_r_monthly_cost'].to_f/frn['number_of_lines'].to_f unless
				(frn['orig_r_monthly_cost'].nil? || frn['number_of_lines'].nil? || frn['number_of_lines'].to_f == 0)
			conn_lines += frn['number_of_lines'].to_i
		end
		@single_ctype_stats = {}
		@single_ctype_stats[conn_type] = {}
		@single_ctype_stats[conn_type]['price_median'] = percentile(conn_prices, 50)
	else 
		# pricing for individual service/bandwidth types
		single_ctype_frns = FundingRequest.connection.select_all(@@queries[:single_ctype_frns_query])	
		@conn_types = ['10 Gbps fiber', '1 Gbps fiber', '100 Mbps fiber', '10 Mbps fiber', 'T3/DS3 (45 Mbps)', 'T1/DS1 (1.5 Mbps)']
		@single_ctype_stats = {}
		conn_types.each do |conn_type|
			frns = single_ctype_frns.select { |frn| frn['speed_type_category'] == conn_type}
			conn_prices = []
			conn_lines = conn_total_requests = 0
			frns.each do |frn|
				# commented out line would calculate median of lines rather than median of requests
				# conn_prices.concat( Array.new(frn['number_of_lines'].to_i) {frn['orig_r_monthly_cost'].to_d/frn['number_of_lines'].to_d} ) 
				conn_prices << frn['orig_r_monthly_cost'].to_f/frn['number_of_lines'].to_f unless
					(frn['orig_r_monthly_cost'].nil? || frn['number_of_lines'].nil? || frn['number_of_lines'].to_f == 0)
				conn_lines += frn['number_of_lines'].to_i
				conn_total_requests += frn['orig_r_monthly_cost'].to_f
			end
			@single_ctype_stats[conn_type] = {}
			@single_ctype_stats[conn_type]['price_p25'] = percentile(conn_prices, 25)
			@single_ctype_stats[conn_type]['price_median'] = percentile(conn_prices, 50)
			@single_ctype_stats[conn_type]['price_p75'] = percentile(conn_prices, 75)
			@single_ctype_stats[conn_type]['lines'] = conn_lines
			@single_ctype_stats[conn_type]['total_requests'] = conn_total_requests
			@single_ctype_stats[conn_type]['frns'] = frns.length
		end
		
		# requested funding by connection type and connection speed
		@item24_requests = FundingRequest.connection.select_all(@@queries[:item24_requests_query])[0]["sum"]
		@percent_of_p1 = @item24_requests.to_f / FundingRequest.connection.select_all(@@queries[:total_p1requests_query])[0]["sum"].to_f
	
		@requests_by_type = FundingRequest.connection.select_all(@@queries[:requests_by_type_query])
		@multiple_types = FundingRequest.connection.select_all(@@queries[:multiple_types_query])[0]

		@requests_by_speed = FundingRequest.connection.select_all(@@queries[:requests_by_speed_query])
		@multiple_speeds = FundingRequest.connection.select_all(@@queries[:multiple_speed_query])[0]

		@speed_tier_names = { '1' => '< 1.5 Mbps', '2' => '1.5 - 9 Mbps', '3' => '10 - 99 Mbps', 
							  '4' => '100 - 999 Mbps', '5' => '1 - 9.9 Gbps', '6' => '10+ Gbps'} 
		
		# overall requested funding
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

  	@@queries[:total_p1requests_query] = <<-endquery
		SELECT SUM(orig_commitment_request) 
		FROM funding_requests
		WHERE f471_form_status = 'CERTIFIED' AND 
			orig_category_of_service IN ('TELCOMM SERVICES','INTERNET ACCESS')
		endquery
		
	@@queries[:requests_by_type_query] = <<-endquery
		WITH frn_num_connection_types AS (
			SELECT frn, COUNT(*) AS count_types
			FROM ( SELECT DISTINCT frn, type_of_connections
			   	   FROM connections ) as t1
			GROUP BY frn )

		SELECT type_of_connections, SUM(t1.num_lines) AS lines, SUM(funding_requests.orig_commitment_request) AS request
		FROM ( SELECT frn, type_of_connections, SUM(number_of_lines) AS num_lines 
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_connection_types WHERE count_types = 1) AND
				type_of_connections != 'Cellular Wireless' 
			   GROUP BY frn, type_of_connections
			   HAVING SUM(number_of_lines) < 5000 ) AS t1 
			   LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED'
		GROUP BY type_of_connections
		ORDER BY SUM(funding_requests.orig_commitment_request) DESC;
		endquery

	@@queries[:multiple_types_query] = <<-endquery
		WITH frn_num_connection_types AS (
			SELECT frn, COUNT(*) AS count_types
			FROM ( SELECT DISTINCT frn, type_of_connections
			   	   FROM connections ) as t1
			GROUP BY frn )
	
		SELECT SUM(t1.num_lines) AS lines, SUM(funding_requests.orig_commitment_request) AS request
		FROM ( SELECT frn, SUM(number_of_lines) AS num_lines
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_connection_types WHERE count_types > 1) 
			   GROUP BY frn 
			   HAVING SUM(number_of_lines) < 5000 ) AS t1 
		LEFT JOIN funding_requests
		ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED';
		endquery
	
	@@queries[:requests_by_speed_query] = <<-endquery
		WITH frn_num_speeds AS (
			SELECT frn, COUNT(*) AS count_speeds
			FROM ( SELECT DISTINCT frn, download_speed
			   	   FROM connections ) as t1
			GROUP BY frn )
			
		SELECT t1.speed_tier, SUM(t1.num_lines) AS lines, SUM(funding_requests.orig_commitment_request) AS request
		FROM ( SELECT frn, SUM(number_of_lines) AS num_lines, 
			   CASE WHEN download_speed < 1.5 THEN 1 
			   		WHEN 1.5 <= download_speed AND download_speed < 10 THEN 2 
			   		WHEN 10 <= download_speed AND download_speed < 100 THEN 3 
			   		WHEN 100 <= download_speed AND download_speed < 1000 THEN 4 
			   		WHEN 1000 <= download_speed AND download_speed < 10000 THEN 5 
					WHEN 10000 <= download_speed THEN 6
			   END AS speed_tier
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_speeds WHERE count_speeds = 1) AND 
			    type_of_connections != 'Cellular Wireless' 
			   GROUP BY frn, speed_tier 
			   HAVING SUM(number_of_lines) < 5000 ) AS t1 
			   LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED'
		GROUP BY t1.speed_tier
		ORDER BY t1.speed_tier ASC;
		endquery
		
	@@queries[:multiple_speed_query] = <<-endquery
		WITH frn_num_speeds AS (
			SELECT frn, COUNT(*) AS count_speeds
			FROM ( SELECT DISTINCT frn, download_speed
			   	   FROM connections ) as t1
			GROUP BY frn )

		SELECT SUM(t1.num_lines) AS lines, SUM(funding_requests.orig_commitment_request) AS request
		FROM ( SELECT frn, SUM(number_of_lines) AS num_lines
			   FROM connections
			   WHERE frn IN (SELECT frn FROM frn_num_speeds WHERE count_speeds > 1) AND
				type_of_connections != 'Cellular Wireless' 
			   GROUP BY frn 
			   HAVING SUM(number_of_lines) < 5000 ) AS t1 
		LEFT JOIN funding_requests ON t1.frn = funding_requests.frn
		WHERE funding_requests.f471_form_status = 'CERTIFIED';
		endquery
		
	@@queries[:single_ctype_frns_query] = <<-endquery
		WITH single_connection_type_frns AS (
			SELECT t1.frn, COUNT(*) 
			FROM (SELECT DISTINCT frn, type_of_connections, download_speed
		 		  FROM connections) AS t1
			GROUP BY t1.frn 
			HAVING COUNT(*) = 1 )
	
		SELECT connections.number_of_lines, funding_requests.orig_r_monthly_cost, 
			CASE WHEN connections.type_of_connections='Fiber optic/OC-x' AND connections.download_speed = 10 THEN '10 Mbps fiber'
				 WHEN connections.type_of_connections='Fiber optic/OC-x' AND connections.download_speed = 100 THEN '100 Mbps fiber'
			     WHEN connections.type_of_connections='Fiber optic/OC-x' AND connections.download_speed >= 1000 AND connections.download_speed < 1100 THEN '1 Gbps fiber'
			     WHEN connections.type_of_connections='Fiber optic/OC-x' AND connections.download_speed >= 10000 AND connections.download_speed < 11000 THEN '10 Gbps fiber'
			     WHEN connections.type_of_connections='T1/DS-1' AND connections.download_speed = 1.5 THEN 'T1/DS1 (1.5 Mbps)'
			     WHEN connections.type_of_connections='T3/DS-3' AND connections.download_speed = 45 THEN 'T3/DS3 (45 Mbps)'
			     ELSE 'other'
			END AS speed_type_category
		FROM connections LEFT JOIN funding_requests ON connections.frn = funding_requests.frn
		WHERE connections.frn IN (SELECT frn FROM single_connection_type_frns) AND
			connections.number_of_lines < 5000
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
  
  def percentile(array, p)
	sorted_array = array.sort
    rank = (p.to_d / 100) * (array.length + 1)
    
    if array.length == 0
      return nil
    elsif rank.modulo(1) != 0.0
      sample_0 = sorted_array[rank.truncate - 1]
      sample_1 = sorted_array[rank.truncate]

      return (rank.modulo(1)  * (sample_1 - sample_0)) + sample_0
    else
      return sorted_array[rank - 1]
    end    
  end
end