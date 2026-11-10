class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_password_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    Padlock::Password::OnForgottenJob.perform_later(params[:username])

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @password.replace(params.permit(:password, :password_confirmation))
      @password.holder.sessions.destroy_all
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private

  def set_password_by_token
    @password = Padlock::Password.replaceable.find_by_key_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
  end
end
