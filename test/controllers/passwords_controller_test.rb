require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = character_players(:luffy)
    @username = padlock_usernames(:one)
    @password = padlock_passwords(:one)
  end

  test "new" do
    get new_password_path
    assert_response :success
    assert_select "input[name=username]"
  end

  test "create queues the username lookup" do
    assert_reset_requested(@username.key)
  end

  test "create for an unknown username queues the same lookup and shows the same notice" do
    assert_reset_requested("missing-user@example.com")
  end

  test "edit allows resetting a replaceable password" do
    get edit_password_path(padlock_passwords(:two).key_reset_token)
    assert_response :success
    assert_select "input[name=replacement_key]"
    assert_select "input[name=replacement_key_confirmation]"
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_invalid_reset_link
  end

  test "edit with expired password reset token" do
    token = @password.key_reset_token

    travel 16.minutes do
      get edit_password_path(token)
      assert_invalid_reset_link
    end
  end

  test "edit allows resetting an expired password" do
    @password.update!(expires_at: 1.second.ago)

    get edit_password_path(@password.key_reset_token)
    assert_response :success
  end

  test "edit redirects for a replaced password" do
    token = padlock_passwords(:previous).key_reset_token

    get edit_password_path(token)
    assert_invalid_reset_link
  end

  test "successful update redirects to sign in and revokes only the holder's sessions" do
    holder_session = Session.create!(character: @player)
    other_session = Session.create!(character: character_players(:nami))

    put password_path(@password.key_reset_token), params: { replacement_key: "new", replacement_key_confirmation: "new" }

    assert_redirected_to new_session_path
    assert_not Session.exists?(holder_session.id)
    assert Session.exists?(other_session.id)
    assert_equal "Password has been reset.", flash[:notice]
  end

  test "update with non matching passwords redirects with an alert and preserves sessions" do
    token = @password.key_reset_token
    holder_session = Session.create!(character: @player)

    put password_path(token), params: { replacement_key: "no", replacement_key_confirmation: "match" }

    assert_redirected_to edit_password_path(token)
    assert Session.exists?(holder_session.id)
    assert_equal "Passwords did not match.", flash[:alert]
  end

  test "update with a reused password redirects with a history alert and preserves sessions" do
    token = @password.key_reset_token
    holder_session = Session.create!(character: @player)

    put password_path(token), params: { replacement_key: "previous-password", replacement_key_confirmation: "previous-password" }

    assert_redirected_to edit_password_path(token)
    assert Session.exists?(holder_session.id)
    assert_equal "Your new password must be different from your previous passwords.", flash[:alert]
  end

  test "update with an invalid token redirects to request a new reset link" do
    put password_path("invalid token"), params: { replacement_key: "new", replacement_key_confirmation: "new" }

    assert_invalid_reset_link
  end

  private
    def assert_reset_requested(username)
      assert_enqueued_with(job: Padlock::Password::OnForgottenJob, args: [ username ]) do
        assert_enqueued_emails 0 do
          post passwords_path, params: { username: username }
        end
      end
      assert_redirected_to new_session_path

      follow_redirect!
      assert_select "#notice", "Password reset instructions sent (if user with that email address exists)."
    end

    def assert_invalid_reset_link
      assert_redirected_to new_password_path

      follow_redirect!
      assert_select "#alert", "Password reset link is invalid or has expired."
    end
end
