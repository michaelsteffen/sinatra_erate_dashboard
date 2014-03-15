class FundingRequest < ActiveRecord::Base
	def USAC_f471_URL
		usac_fy = self.funding_year - 1997
		app_no = self.f471_application_number
		return "http://www.slforms.universalservice.org/Form471Expert/FY#{usac_fy}/PrintPreview.aspx?appl_id=#{app_no}"
	end
	
	def orig_priority
		return "p1" if ['TELCOMM SERVICES','INTERNET ACCESS'].include?(self.orig_category_of_service)
		return "p2" if ['INTERNAL CONNECTIONS','INTERNAL CONNECTIONS MNT'].include?(self.orig_category_of_service)
	end
end

class Connection < ActiveRecord::Base
end

class Upload < ActiveRecord::Base
	serialize :import_errors, Array
end