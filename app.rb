# to do:
# - !! application dashboard and drill down counts don't match
# - add drill downs to individual applications, BENs, etc.
# - change dashboard order per Mike B suggestions
# - change "jump-the-line" presentation per Mark W suggestion
# - add line counts to first two items in item 24 tables
# - add block 4 data
# - add totals to demand table
# - better error handling for uplaod files
#		- check that files are actually CSV files
# 		- do initial error checking of upload file headers
#		- catch other errors??
# - add activerecord multiple insert to speed up data uploads
# - move to-do list to github tickets
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
  	@form471_small = Form471DashboardPresenter.new(:small)
  	@item24_small = Item24DashboardPresenter.new(:small)
  	erb :"index"
end

get "/dashboards/form471" do
  redirect "/working" unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"

  @title = "Form 471 Dashboard"
  @form471_dashboard = Form471DashboardPresenter.new
  erb :"/dashboards/form471"
end

get "/dashboards/item24" do
  redirect "/working" unless Upload.where(:file_type => "DRT").last.import_status == "Complete" and Upload.where(:file_type => "Item24").last.import_status == "Complete"

  @title = "Item 24 Dashboard"
  @item24_dashboard = Item24DashboardPresenter.new
  erb :"/dashboards/item24"
end

get "/dashboards/jump_the_line" do
  @title = "Jump the Line Dashboard"
  erb :"/dashboards/jump_the_line"
end

get "/applications/by_type/:type/?:sort?/?:page_len?/?:page?" do
  @title = "Applications"
  @app_presenter = ApplicationPresenter.new(@params[:type], @params[:sort], @params[:page_len], @params[:page])
  erb :"/applications/by_type"
end

get "/applicants/by_type/:type/?:sort?/?:page_len?/?:page?" do
  @title = "Applicants"
  @appl_presenter = ApplicantPresenter.new(@params[:type], @params[:sort], @params[:page_len], @params[:page])
  erb :"/applicants/by_type"
end

get "/data_upload/new_upload" do
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
      "Test E-rate Dashboard: #{@title}"
    else
      "Test E-rate Dashboard"
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