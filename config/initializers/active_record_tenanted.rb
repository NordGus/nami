# This initializer configs activerecord-tenanted

module TenantSlug
  def self.resolve(_request)
    # complex behavior to pull the tenant out of the request path
  end
end

Rails.application.configure do
  config.active_record_tenanted.connection_class = "TenantedApplicationRecord"
  config.active_record_tenanted.tenant_resolver = ->(request) { TenantSlug.resolve(request) }
end
