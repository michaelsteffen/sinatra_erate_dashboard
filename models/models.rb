class FundingRequest < ActiveRecord::Base
end

class Connection < ActiveRecord::Base
end

class Upload < ActiveRecord::Base
	  serialize :import_errors, Array
end