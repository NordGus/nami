class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if (padlock_password = Padlock::Password.includes(:username).active.authenticate_by(username: { key: params[:username] }, key: params[:password]))
      start_new_session_for padlock_password.character
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another username or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
