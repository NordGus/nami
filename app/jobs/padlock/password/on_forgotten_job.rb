class Padlock::Password::OnForgottenJob < ApplicationJob
  queue_as :default

  def perform(username)
    return :username_blank if username.blank?

    player = Character::Player.includes(:username, :password).find_by(username: { key: username })

    return :invalid_username if player.blank?

    PasswordsMailer.reset(player).deliver_later

    :password_reset_send
  end
end
