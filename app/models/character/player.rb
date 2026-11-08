class Character::Player < Character
  has_one :username, class_name: "Padlock::Username", foreign_key: :holder_id, dependent: :destroy
  has_one :password, -> { active }, class_name: "Padlock::Password", foreign_key: :holder_id, dependent: :destroy
  has_one :replaceable_password, -> { replaceable }, class_name: "Padlock::Password", foreign_key: :holder_id, dependent: :destroy
  has_many :previous_passwords, -> { replaced }, class_name: "Padlock::Password", foreign_key: :holder_id, dependent: :destroy
end
