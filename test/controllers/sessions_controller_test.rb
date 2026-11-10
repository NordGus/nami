require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = character_players(:luffy)
    @username = padlock_usernames(:one)
    @password = padlock_passwords(:one)
  end

  test "new" do
    get new_session_path
    assert_response :success
    assert_select "input[name=username]"
    assert_select "input[name=password]"
  end

  test "create with valid credentials returns to the protected URL" do
    delete session_path
    assert_redirected_to new_session_path

    assert_difference "Session.count", 1 do
      post session_path, params: { username: @username.key, password: "password" }
    end

    assert_redirected_to session_path
    assert cookies[:session_id].present?
    assert_equal @player, Session.order(:id).last.character
  end

  test "create with invalid credentials" do
    assert_sign_in_rejected(password: "wrong")
  end

  test "create with an unknown username" do
    assert_sign_in_rejected(username: "missing@example.com")
  end

  test "create with an expired password" do
    @password.update!(expires_at: 1.second.ago)

    assert_sign_in_rejected
  end

  test "create with a replaced password" do
    assert_sign_in_rejected(password: "previous-password")
  end

  test "destroy" do
    sign_in_as(@player)
    session_id = Current.session.id

    assert_difference "Session.count", -1 do
      delete session_path
    end

    assert_response :see_other
    assert_redirected_to new_session_path
    assert cookies[:session_id].blank?
    assert_not Session.exists?(session_id)
  end

  private
    def assert_sign_in_rejected(**credentials)
      assert_no_difference "Session.count" do
        post session_path, params: { username: @username.key, password: "password" }.merge(credentials)
      end

      assert_redirected_to new_session_path
      assert cookies[:session_id].blank?
      assert_equal "Try another username or password.", flash[:alert]
    end
end
