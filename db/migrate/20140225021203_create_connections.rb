class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
  	  t.text :frn, :f471_application_number, :ben, :applicant_name, :type_of_connections
	  t.integer :number_of_lines
	  t.decimal :download_speed
	  
      t.timestamps  
	end
	
	add_index :connections, :frn
  end
end
