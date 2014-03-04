#todo:
# - write item 24 dashboard
# - refactor: create "get from CSV" method for FundingRequest and Connections models, passing file name
# - refactor: move CSV mappings into FundingRequest and Connections models
# - refactor: move to database.yml for configuration
# - refactor: fix table styling for hidden row

require 'sinatra'
require 'sinatra/activerecord'
require 'action_view/helpers/number_helper'
require 'csv'

require './config/environments' 	# database configuration
require './config/csv_mappings'		# mapping of USAC csv column titles to db columns
Dir["./models/*.rb"].each {|file| require file }
Dir["./presenters/*.rb"].each {|file| require file }

include ActionView::Helpers::NumberHelper

get "/" do
  @title = "Basic Dashboard"
  @basic_dashboard = BasicDashboardPresenter.new
  erb :"index"
end

get "/dashboards/item24" do
  @title = "Item 24 Dashboard"
  @item24_dashboard = Item24DashboardPresenter.new
  erb :"/dashboards/item24"
end

get "/funding_requests/bulkupload" do
	@upload_errors = []
	
  	FundingRequest.delete_all
  	frs_csv_text = File.read(File.join(settings.root, 'user_uploads', 'funding_requests.csv'))
	frs_csv = CSV.parse(frs_csv_text, :headers => true)

  	frs_csv.each do |row|
 		renamed_keys_row = Hash[ row.map { |key, value| [FundingRequestsMapping[key] || key, value] } ]
 		
 		begin
 			dummy_funding_request = FundingRequest.new(renamed_keys_row)
 			renamed_keys_row.each_key do |key|			# eliminate dollar signs and commas for numerical fields
 		  		if ["BigDecimal","Fixnum"].include?(eval("dummy_funding_request.#{ key }.class").to_s)
 		  			renamed_keys_row[key] = renamed_keys_row[key].gsub(/[$,]/, '') 	
 		  		end	
			end
 			FundingRequest.create(renamed_keys_row)
 		rescue => any_error
 			@upload_errors << "DRT Data Upload: " + any_error.message
 		end
	end
 	
 	Connections.delete_all
  	connections_csv_text = File.read(File.join(settings.root, 'user_uploads', 'connections.csv'))
	connections_csv = CSV.parse(connections_csv_text, :headers => true)
	
  	connections_csv.each do |row|
  		renamed_keys_row = Hash[ row.map { |key, value| [ConnectionsMapping[key] || key, value] } ]

  		begin
  			dummy_connection = Connections.new(renamed_keys_row)
 			renamed_keys_row.each_key do |key|			# eliminate dollar signs and commas for numerical fields
		  		if ["BigDecimal","Fixnum"].include?(eval("dummy_connection.#{ key }.class").to_s)
		  			renamed_keys_row[key] = renamed_keys_row[key].gsub(/[$,]/, '') 	
		  		end	
			end
 			Connections.create(renamed_keys_row)
  		rescue => any_error
 			@upload_errors << "Connections Data Upload: " + any_error.message
 		end
 	end
 	
   	@successful_frn_uploads = 0
  	@successful_connections_uploads = 0
  			
  	erb :"/funding_requests/bulkupload"
end

get "/funding_requests/" do
  @funding_requests = FundingRequest.order("frn DESC")
  @title = "FRN Index"
  erb :"/funding_requests/index"
end

helpers do
  def title
    if @title
      "Test E-rate Dashboard: #{@title}"
    else
      "Test E-rate Dashboard"
    end
  end
end