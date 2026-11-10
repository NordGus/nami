require "test_helper"

class Padlock::UsernameTest < ActiveSupport::TestCase
  test "fixture username belongs to a player and is valid" do
    username = padlock_usernames(:one)

    assert_equal character_players(:luffy), username.holder
    assert_predicate username, :valid?
  end

  test "key must be an email address" do
    username = padlock_usernames(:one)
    username.key = "not-an-email"

    assert_not username.valid?
    assert username.errors[:key].present?
  end

  test "key must be unique" do
    username = padlock_usernames(:one)
    username.key = padlock_usernames(:two).key

    assert_not username.valid?
    assert username.errors.of_kind?(:key, :taken)
  end

  test "a player can only have one username" do
    username = Padlock::Username.new(holder: character_players(:luffy), key: "another@example.com")

    assert_not username.valid?
    assert username.errors.of_kind?(:holder, :taken)
  end
end
