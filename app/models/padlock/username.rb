class Padlock::Username < ApplicationRecord
  belongs_to :holder, class_name: "Character::Player", foreign_key: :holder_id

  validates :holder, presence: true, uniqueness: true
  validates :key, presence: true, uniqueness: true, email: true
end
