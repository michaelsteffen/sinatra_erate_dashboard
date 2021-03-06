# to do:
# - finish first draft of processing dashboard
# - add funding request count to prices table
# - add totals to first applicant table?
# - add totals to demand table
# - create infrastructure dashboard
# - add block 4 table to applicant dashboard
# - add entity count to applicant list
# - add click-through for connection speed and type spending info
# - highlight active section in nav
# - refactor: add css classes to front page
# - add drill down for item 24 data
# - better error handling for upload files
#		- check that files are actually CSV files
# 		- do initial error checking of upload file headers
#		- catch other errors??
# - add individual FRN, Application, BEN display
# - add activerecord multiple insert to speed up data uploads
# - move to-do list to github tickets
# - refactor: rewrite applicant, application, and frn presenters to take a parameter hash
# - refactor: create "get from CSV" method for FundingRequest and Connections models, passing file name
# - refactor: move CSV mappings into FundingRequest and Connections models?
# - refactor: add css class for table styling for hidden row
# - refactor: turn large front page text into css classes
# - add test suite
# - refactor: add loop for upload types to upload log page
# - refactor: more efficient query for "unless" calls to test if import is ongoing
# - eliminate use of <br> for spacing
# - normalize data structure?
# - move to database.yml for configuration?

require 'rubygems'
require "bundler/setup"

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'action_view/helpers/number_helper'
require 'csv'

require './config/environments' 	# database configuration
require './config/csv_mappings'		# mapping of USAC csv column titles to db columns
Dir["./models/*.rb"].each {|file| require file }		# all models
Dir["./presenters/*.rb"].each {|file| require file }	# all presenters

include ActionView::Helpers::NumberHelper
enable :sessions

get "/" do
    redirect "/working" unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"
  	
  	@title = "Welcome"
  	@applicant_small = ApplicantDashboardPresenter.new(:small)
  	@spending_small = SpendingDashboardPresenter.new(:small)
  	@processing_small = ProcessingDashboardPresenter.new(:small)
  	erb :"index"
end

get "/dashboards/infrastructure" do
  @title = "Broadband"
  erb :"/dashboards/stub"
end

get "/dashboards/apps" do
  redirect "/working" unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"

  @title = "Applications"
  @applicant_dashboard = ApplicantDashboardPresenter.new
  erb :"/dashboards/applicant_dashboard"
end

get "/dashboards/spending" do
  redirect "/working" unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"

  @title = "Pricing & Spending"
  @spending_dashboard = SpendingDashboardPresenter.new
  erb :"/dashboards/spending_dashboard"
end

get "/dashboards/processing" do
  @title = "Application Processing"
  
  @processing_dashboard = ProcessingDashboardPresenter.new
  erb :"/dashboards/processing_dashboard"
end

get "/application_list" do
  @title = "Applications"
  @application_list = ApplicationListPresenter.new(@params)
  erb :"/list_views/application_list"
end

get "/applicant_list" do
  @title = "Applicants"
  @applicant_list = ApplicantListPresenter.new(@params)
  erb :"/list_views/applicant_list"
end

get "/frn_list" do
  @title = "Funding Requests"
  @frn_list = FundingRequestListPresenter.new(@params)  
  erb :"/list_views/frn_list"
end

get "/data_upload/new_upload" do
  unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"
	flash.now[:alert] = "<strong>Careful!</strong> There is another upload ongoing; starting two simultaneous uploads could cause unpredictable results."
  end

  @title = "Data Upload"
  erb :"/data_upload/new_upload"
end

post "/data_upload/new_upload" do

	if params.has_key?('drt-file') and params.has_key?('item24-file') 
		drt_file = "user_uploads/" + params['drt-file'][:filename].to_s
		File.open(drt_file, "w+") do |f|
			f.write(params['drt-file'][:tempfile].read)
		end

		item24_file = "user_uploads/" + params['item24-file'][:filename].to_s
		File.open(item24_file, "w+") do |f|
			f.write(params['item24-file'][:tempfile].read)
		end
		
		# USAC .csv files have a "byte order mark" gremlin, so need odd encoding
		frs_csv_text = File.read(drt_file, encoding: "bom|utf-8")
		frs_csv = CSV.parse(frs_csv_text, :headers => true)
		connections_csv_text = File.read(item24_file, encoding: "bom|utf-8")
		connections_csv = CSV.parse(connections_csv_text, :headers => true)

		drt_upload = Upload.create(:file_name => drt_file, :file_type => "DRT", :import_status => "In Process", :file_record_count => frs_csv.length, :successful_records => 0, :import_errors => [])
		item24_upload = Upload.create(:file_name => item24_file, :file_type => "Item24", :import_status => "Queued", :file_record_count => connections_csv.length, :successful_records => 0, :import_errors => [])
		
		child_thread = Thread.new do	
			FundingRequest.delete_all
			frs_csv.each_with_index do |row, i|
				renamed_keys_row = Hash[ row.map { |key, value| [FundingRequestsMapping[key] || key, value] } ]
	
				begin
					dummy_funding_request = FundingRequest.new(renamed_keys_row)
					renamed_keys_row.each_key do |key|			# eliminate dollar signs and commas for numerical fields
						if ["BigDecimal","Fixnum"].include?(eval("dummy_funding_request.#{ key }.class").to_s)
							renamed_keys_row[key].gsub!(/[$,]/, '') 	
						end	
					end
					FundingRequest.create(renamed_keys_row)
					drt_upload.successful_records += 1
				rescue => any_error
					drt_upload.import_errors << any_error.message
				end
				
				#write status to database every 500 rows
				if (i+1).modulo(500).zero?
					drt_upload.save
				end
			end
			File.delete(drt_file)		#since Heroku file storage is ephemeral anyway, might as well delete
			drt_upload.import_status = "Complete"
			drt_upload.save
	
			item24_upload.import_status = "In Progress"
			item24_upload.save
			Connection.delete_all	
			connections_csv.each_with_index do |row, i|
				renamed_keys_row = Hash[ row.map { |key, value| [ConnectionsMapping[key] || key, value] } ]

				begin
					dummy_connection = Connection.new(renamed_keys_row)
					renamed_keys_row.each_key do |key|			# eliminate dollar signs and commas for numerical fields
						if ["BigDecimal","Fixnum"].include?(eval("dummy_connection.#{ key }.class").to_s)
							renamed_keys_row[key] = renamed_keys_row[key].gsub(/[$,]/, '') 	
						end	
					end
					Connection.create(renamed_keys_row)
					item24_upload.successful_records += 1
				rescue => any_error
					item24_upload.import_errors << any_error.message
				end
				
				#write status to database every 500 rows
				if (i+1).modulo(500).zero?
					item24_upload.save
				end
			end
			File.delete(item24_file)		#since Heroku file storage is ephemeral anyway, might as well delete
			item24_upload.import_status = "Complete"
			item24_upload.save
		end
		
		redirect "/data_upload/upload_log", :success => "<strong>Success!</strong> Your data import has started. Reload this page to monitor progress.  Dashboards will be unavailable until the import completes."
	else
		flash.now[:error] = "<strong>Ack!</strong> You must upload both a drt file and the associated item 24 file together."
		erb :"/data_upload/new_upload"
	end
end

get "/data_upload/upload_log" do
  @title = "Upload Log"
  @drt_upload = Upload.where(:file_type => "DRT").last
  @item24_upload = Upload.where(:file_type => "Item24").last
  erb :"/data_upload/upload_log"
end

get "/working" do
  @title = "Upload in progress . . ."
  erb :"working"
end

helpers do
  def title
    if @title
      "E-rate Dashboard Mock-Up: #{@title}"
    else
      "E-rate Dashboard Mock-Up"
    end
  end
  
  def flash_class(level)
    case level
        when :notice then "alert alert-info alert-dismissable"
        when :success then "alert alert-success alert-dismissable"
        when :alert then "alert alert-warning alert-dismissable"
    	when :error then "alert alert-danger alert-dismissable"
    end
  end
end