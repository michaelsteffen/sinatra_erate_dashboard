#todo:
# - refactor: create "get from CSV" method for FundingRequest and Connections models, passing file name
# - move CSV mappings into FundingRequest and Connections models
# - move to database.yml for configuration

require 'sinatra'
require 'sinatra/activerecord'
require 'csv'

require './config/environments' 	# database configuration
require './config/csv_mappings'		# mapping of USAC csv column titles to db columns
require './models'
require './presenters'

get "/" do
  @title = "Basic Dashboard"
  @basic_dashboard = BasicDashboardPresenter.new
  erb :"index"
end

get "/funding_requests/bulkupload" do
  	FundingRequest.delete_all
  	frs_csv_text = File.read(File.join(settings.root, 'user_uploads', 'funding_requests.csv'))
	frs_csv = CSV.parse(frs_csv_text, :headers => true)
  	frs_csv.each do |row|
  		renamed_keys_row = Hash[ row.map { |key, value| [FundingRequestsMappings[key] || key, value] } ]
  		FundingRequest.create(renamed_keys_row)
 	end
 	
 	Connections.delete_all
  	connections_csv_text = File.read(File.join(settings.root, 'user_uploads', 'connections.csv'))
	connections_csv = CSV.parse(connections_csv_text, :headers => true)
  	connections_csv.each do |row|
  		renamed_keys_row = Hash[ row.map { |key, value| [ConnectionsMapping[key] || key, value] } ]
  		Connections.create(renamed_keys_row)
 	end
  	
  	@upload_status = "#{frs_csv.length} records in funding request csv file; #{frs_csv.length} records in connections csv file."	
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