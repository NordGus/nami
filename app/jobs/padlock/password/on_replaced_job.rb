## Padlock::Password::OnReplacedJob
# Handles password's holder's password history resizing in the background, so the password history system can stay consistent
class Padlock::Password::OnReplacedJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(padlock, *) { padlock }, duration: 1.minute, group: "PadlockActions"

  retry_on ActiveRecord::RecordNotDestroyed, wait: 10.seconds, attempts: 10, report: true

  discard_on ActiveRecord::RecordNotFound

  def perform(password)
    return :no_password unless password.present?

    history_length = Padlock::Password.history_length
    previous_passwords = password.holder.previous_passwords.limit(history_length).order(id: :desc).to_a

    # If the number of previous passwords is less than the history length, then there is no need to delete anything.
    # Only when the holder's previous passwords reach the history length will we need to delete the oldest password.
    return :history_has_not_been_exhausted if previous_passwords.size < history_length

    # We only delete the last password because is outside the maximum length of passwords the holder's history can contain,
    # because let's remember that the holder has a password under password that we are not seeing here. So by limiting
    # previous_passwords to history_length, we are effectively taking the oversized history to trim it down to the max
    # history length by deleting the oldest padlock in the limit.
    #
    # We do not need to delete more than the last password, because the dependency association replaced_padlock will
    # recursively destroy the passwords below it in the history.
    previous_passwords.last.destroy!

    :holder_password_history_trimmed
  end
end
