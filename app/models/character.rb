class Character < ApplicationRecord
  has_many :sessions, dependent: :destroy
end
