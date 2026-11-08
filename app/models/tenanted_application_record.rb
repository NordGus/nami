class TenantedApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  tenanted "ledgers"
end
