require "test_helper"

class Padlock::Password::OnReplacedJobTest < ActiveJob::TestCase
  test "missing passwords do not change history" do
    assert_no_difference "Padlock::Password.count" do
      assert_equal :no_password, Padlock::Password::OnReplacedJob.perform_now(nil)
    end
  end

  test "replacing luffy's password trims older history recursively without affecting nami" do
    luffy = character_players(:luffy)
    nami = character_players(:nami)
    password = padlock_passwords(:one)
    nami_password = padlock_passwords(:two)
    older_ids = padlock_passwords(:older, :oldest).map(&:id)
    replacement = nil

    assert_difference "Padlock::Password.count", -1 do
      assert_performed_jobs 1, only: Padlock::Password::OnReplacedJob do
        replacement = password.replace_padlock(replacement_key: "new-luffy", replacement_key_confirmation: "new-luffy")
      end
    end

    assert_equal replacement, luffy.reload.password
    assert replacement.authenticate_key("new-luffy")
    assert_equal replacement, password.reload.replacement_padlock
    assert_equal [ password.id, padlock_passwords(:previous).id ], luffy.previous_passwords.order(id: :desc).pluck(:id)
    assert_not Padlock::Password.exists?(id: older_ids)
    assert_equal nami_password, nami.reload.password
    assert_empty nami.previous_passwords
  end

  test "replacing nami's password preserves history until full and then trims only nami's oldest password" do
    nami = character_players(:nami)
    password = padlock_passwords(:two)
    luffy_passwords = Padlock::Password.where(holder: character_players(:luffy)).order(:id).map(&:attributes)
    replacements = []

    3.times do |index|
      replacement = nil
      assert_difference "Padlock::Password.where(holder: nami).count", index < 2 ? 1 : 0 do
        assert_performed_jobs 1, only: Padlock::Password::OnReplacedJob do
          replacement = password.replace_padlock(replacement_key: "new-nami-#{index}", replacement_key_confirmation: "new-nami-#{index}")
        end
      end
      assert_equal replacement, nami.reload.password
      assert_equal replacement, password.reload.replacement_padlock
      replacements << replacement
      password = replacement
    end

    assert_equal replacements.first(2).reverse.map(&:id), nami.previous_passwords.order(id: :desc).pluck(:id)
    assert_not Padlock::Password.exists?(padlock_passwords(:two).id)
    assert_equal luffy_passwords, Padlock::Password.where(holder: character_players(:luffy)).order(:id).map(&:attributes)
  end
end
