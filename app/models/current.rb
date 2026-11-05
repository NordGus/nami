class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :character, to: :session, allow_nil: true
end
