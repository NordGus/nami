class Padlock::Password < ApplicationRecord
  has_secure_password :key

  belongs_to :holder, class_name: "Character::Player", foreign_key: :holder_id
  belongs_to :replacement_padlock, class_name: "Padlock::Password", foreign_key: :replaced_by_id, optional: true

  has_one :username, class_name: "Padlock::Username", through: :holder
  has_one :replaced_padlock, class_name: "Padlock::Password", foreign_key: :replaced_by_id, dependent: :destroy

  scope :active, -> { where(replaced_by_id: nil, expires_at: Time.current...) }
  scope :replaced, -> { where.not(replaced_by_id: nil) }
  scope :replaceable, -> { where(replaced_by_id: nil) }
  scope :holders_history, ->(holder) { replaced.where(holder:).limit(history_length) }

  validate :key_uniqueness_in_holders_history, if: :new_record?

  class AlreadyReplacedError < StandardError; end

  def self.history_length
    3
  end

  def self.duration
    3.months
  end

  def still_active?
    replaced_by_id.nil?
  end

  def replace_padlock(replacement_key:, replacement_key_confirmation:)
    fail AlreadyReplacedError, "already replaced" unless still_active?

    new_password = Padlock::Password.new(
      holder:,
      key: replacement_key,
      key_confirmation: replacement_key_confirmation,
      expires_at: self.class.duration.from_now
    )

    # Use a transaction to ensure that the padlock is not created if the replacement fails.
    transaction do
      new_password.save!

      # We need to update the current padlock's replacement reference so is registered as replaced in the database so the
      # OnReplacedJob job/event handler can be processed, because is a supposition of the platform later.
      update!(replacement_padlock: new_password)

      OnReplacedJob.perform_later(self)
    rescue StandardError => e
      Rails.logger.debug { e.message }
      Rails.logger.debug { e.backtrace&.join("\n") }

      raise ActiveRecord::Rollback
    end

    new_password
  end

  private

  # Validates that the password is unique in the holder's history.
  #
  # @return [ActiveModel::Error, NilClass]
  def key_uniqueness_in_holders_history
    digests = Padlock::Password.holders_history(holder).pluck(:key_digest)

    # We add a taken error to the key if it matches an existing digest in the character's password history.
    #
    # BCrypt::Password.new(digest) allows us to compare a plain text string against a hashed string correctly. If the
    # has no more than 10 padlocks, the computational cost for this comparison is negligible.
    errors.add(:key, :taken) if digests.any? { |digest| BCrypt::Password.new(digest).is_password? key }
  end
end
