class Padlock::Password < ApplicationRecord
  has_secure_password :key

  belongs_to :holder, class_name: "Character::Player", foreign_key: :holder_id
  belongs_to :_replacement, class_name: "Padlock::Password", foreign_key: :replaced_by_id, optional: true

  has_one :username, class_name: "Padlock::Username", through: :holder
  has_one :_replaces, class_name: "Padlock::Password", foreign_key: :replaced_by_id, dependent: :destroy

  scope :active, -> { where(replaced_by_id: nil, expires_at: Time.current...) }
  scope :replaced, -> { where.not(replaced_by_id: nil) }
  scope :replaceable, -> { where(replaced_by_id: nil) }
  scope :holders_history, ->(holder) { replaced.where(holder:).limit(history_length) }

  def self.history_length
    3
  end

  def self.duration
    3.months
  end
end
