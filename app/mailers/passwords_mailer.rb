class PasswordsMailer < ApplicationMailer
  def reset(player)
    @password = player.replaceable_password
    mail subject: "Reset your password", to: player.username.key
  end
end
