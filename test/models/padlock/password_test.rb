require "test_helper"

class Padlock::PasswordTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "replacement creates a new password and queues history maintenance for the old password" do
    password = padlock_passwords(:one)

    freeze_time do
      replacement = nil
      assert_difference "Padlock::Password.count", 1 do
        assert_enqueued_with(job: Padlock::Password::OnReplacedJob, args: [ password ]) do
          replacement = password.replace_padlock(replacement_key: "new-password", replacement_key_confirmation: "new-password")
        end
      end

      assert_equal replacement, password.reload.replacement_padlock
      assert_equal password, replacement.replaced_padlock
      assert_equal password.holder, replacement.holder
      assert replacement.authenticate_key("new-password")
      assert_equal 3.months.from_now, replacement.expires_at
      assert_not password.still_active?
      assert replacement.still_active?
    end
  end

  test "invalid replacements return an unsaved password with errors without queuing history maintenance" do
    password = padlock_passwords(:one)

    [ [ "new-password", "mismatch", :key_confirmation, :confirmation ],
      [ "previous-password", "previous-password", :key, :taken ] ].each do |key, confirmation, attribute, type|
      assert_no_enqueued_jobs only: Padlock::Password::OnReplacedJob do
        assert_no_difference "Padlock::Password.count" do
          assert_no_changes -> { password.reload.attributes } do
            replacement = password.replace_padlock(replacement_key: key, replacement_key_confirmation: confirmation)

            assert_not replacement.persisted?
            assert_equal password.holder, replacement.holder
            assert replacement.errors.of_kind?(attribute, type)
          end
        end
      end
    end
  end

  test "replacing an already replaced password raises without creating or queuing anything" do
    assert_no_enqueued_jobs only: Padlock::Password::OnReplacedJob do
      assert_no_difference "Padlock::Password.count" do
        assert_raises(Padlock::Password::AlreadyReplacedError) do
          padlock_passwords(:previous).replace_padlock(replacement_key: "new-password", replacement_key_confirmation: "new-password")
        end
      end
    end
  end

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
