class Character < ApplicationRecord
  has_one :session, dependent: :destroy
end
