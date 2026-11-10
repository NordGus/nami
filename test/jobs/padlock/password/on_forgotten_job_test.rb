require "test_helper"

class Padlock::Password::OnForgottenJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "blank usernames do not enqueue mail" do
    [ nil, "", " " ].each do |username|
      assert_no_enqueued_jobs do
        assert_equal :username_blank, Padlock::Password::OnForgottenJob.perform_now(username)
      end
    end
  end

  test "unknown usernames do not enqueue mail" do
    assert_no_enqueued_jobs do
      assert_equal :invalid_username, Padlock::Password::OnForgottenJob.perform_now("missing@example.com")
    end
  end

  test "known usernames enqueue reset mail for the player" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ character_players(:luffy) ] do
      assert_equal :password_reset_send,
        Padlock::Password::OnForgottenJob.perform_now(padlock_usernames(:one).key)
    end
  end

  test "expired passwords still allow requesting reset mail" do
    padlock_passwords(:one).update!(expires_at: 1.second.ago)

    assert_enqueued_email_with PasswordsMailer, :reset, args: [ character_players(:luffy) ] do
      assert_equal :password_reset_send,
        Padlock::Password::OnForgottenJob.perform_now(padlock_usernames(:one).key)
    end
  end
end
