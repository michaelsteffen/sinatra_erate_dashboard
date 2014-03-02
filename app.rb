#todo:
# - importing of dollar values still broken
# - get import of connections working
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
require './models'
require './presenters'

include ActionView::Helpers::NumberHelper

get "/" do
  @title = "Basic Dashboard"
  @basic_dashboard = BasicDashboardPresenter.new
  erb :"index"
end

get "/funding_requests/bulkupload" do
  	FundingRequest.delete_all
  	frs_csv_text = File.read(File.join(settings.root, 'user_uploads', 'funding_requests.csv'))
	frs_csv = CSV.parse(frs_csv_text, :headers => true)
  	
#  	dummy_renamed_keys = Hash[ frs_csv[0].map { |key, value| [FundingRequestsMapping[key] || key, value] } ]
# 	dummy_funding_request = FundingRequest.new(dummy_renamed_keys)
# 	dummy_renamed_keys.each_key do |key|
# 		puts key.to_s + ": " + (eval("dummy_funding_request.#{ key }.class")).to_s
# 	end

  	frs_csv.each do |row|
 		renamed_keys_row = Hash[ row.map { |key, value| [FundingRequestsMapping[key] || key, value] } ]
 		dummy_funding_request = FundingRequest.new(renamed_keys_row)
 		renamed_keys_row.each_key do |key|			# eliminate dollar signs and commas for numerical fields
 		  	if ["BigDecimal","Fixnum"].include?(eval( "dummy_funding_request.#{ key }.class").to_s)
 		  		renamed_keys_row[key] = renamed_keys_row[key].gsub(/[$,]/, '') 	
 		  	end	
		end
 		FundingRequest.create(renamed_keys_row)
	end
 	
 	#Connections.delete_all
  	#connections_csv_text = File.read(File.join(settings.root, 'user_uploads', 'connections.csv'))
	#connections_csv = CSV.parse(connections_csv_text, :headers => true)
  	#connections_csv.each do |row|
  	#	renamed_keys_row = Hash[ row.map { |key, value| [ConnectionsMapping[key] || key, value] } ]
  	#	Connections.create(renamed_keys_row)
 	#end
  	
  	@upload_status = "Replaced FRN database with #{frs_csv.length} new records in funding request csv file."	
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
      "FCC E-rate Dashboard: #{@title}"
    else
      "FCC E-rate Dashboard"
    end
  end
end