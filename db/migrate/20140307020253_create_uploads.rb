class CreateUploads < ActiveRecord::Migration
  def change
      create_table :uploads do |t|
	  t.text :file_name
  	  t.text :file_type
  	  t.text :import_status
  	  t.integer :file_record_count
	  t.integer :successful_records
  	  t.text :import_errors	# a serialized array of errors - easier than creating a normalized table structure with a separate errors table
	  
      t.timestamps  
	end
  end
end
