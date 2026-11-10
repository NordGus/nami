require "test_helper"

class Padlock::PasswordTest < ActiveSupport::TestCase
  test "active passwords authenticate their key" do
    password = padlock_passwords(:one)

    assert_equal password, password.authenticate_key("password")
    assert_not password.authenticate_key("wrong")
    assert_includes Padlock::Password.active, password
    assert_equal character_players(:luffy), password.holder
    assert_equal padlock_usernames(:one), password.username
  end

  test "expired passwords are replaceable but not active" do
    password = padlock_passwords(:one)
    password.update!(expires_at: 1.second.ago)

    assert_not_includes Padlock::Password.active, password
    assert_includes Padlock::Password.replaceable, password
    assert_not_includes Padlock::Password.replaced, password
  end

  test "replaced passwords are history and cannot be replaced again" do
    password = padlock_passwords(:previous)

    assert_not_includes Padlock::Password.active, password
    assert_not_includes Padlock::Password.replaceable, password
    assert_includes Padlock::Password.replaced, password
    assert_includes Padlock::Password.holders_history(character_players(:luffy)), password
    assert_not_includes Padlock::Password.holders_history(character_players(:nami)), password
  end

  test "reset tokens identify the password" do
    password = padlock_passwords(:one)

    assert_equal password, Padlock::Password.find_by_key_reset_token!(password.key_reset_token)
  end
end
