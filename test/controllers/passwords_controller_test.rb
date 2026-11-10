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

  test "edit" do
    get edit_password_path(@password.key_reset_token)
    assert_response :success
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

  test "edit rejects a replaced password" do
    token = padlock_passwords(:previous).key_reset_token

    get edit_password_path(token)
    assert_invalid_reset_link
  end

  test "update replaces the password and revokes the holder's sessions" do
    holder_session = Session.create!(character: @player)
    other_session = Session.create!(character: character_players(:nami))

    assert_difference "Padlock::Password.count", 1 do
      put password_path(@password.key_reset_token), params: { password: "new", password_confirmation: "new" }
      assert_redirected_to new_session_path
    end

    replacement = @password.reload._replacement
    assert_not_nil replacement
    assert_equal @player, replacement.holder
    assert replacement.authenticate_key("new")
    assert_not Session.exists?(holder_session.id)
    assert Session.exists?(other_session.id)
    assert_equal "Password has been reset.", flash[:notice]
  end

  test "update with non matching passwords preserves the password and sessions" do
    token = @password.key_reset_token
    holder_session = Session.create!(character: @player)

    assert_no_difference "Padlock::Password.count" do
      assert_no_changes -> { @password.reload.attributes } do
        put password_path(token), params: { password: "no", password_confirmation: "match" }
      end
    end

    assert_redirected_to edit_password_path(token)
    assert Session.exists?(holder_session.id)
    assert_equal "Passwords did not match.", flash[:alert]
  end

  test "update with an invalid token does not change passwords" do
    assert_no_difference "Padlock::Password.count" do
      put password_path("invalid token"), params: { password: "new", password_confirmation: "new" }
    end

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
