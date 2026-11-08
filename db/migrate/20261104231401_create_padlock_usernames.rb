class CreatePadlockUsernames < ActiveRecord::Migration[8.1]
  def change
    create_table :padlock_usernames do |t|
      t.text :key, null: false
      t.belongs_to :holder, null: false, foreign_key: { to_table: :characters }

      t.timestamps
    end

    add_index :padlock_usernames, :key, unique: true
    add_index :padlock_usernames, :holder_id, unique: true, using: :btree, name: :padlock_usernames_unique_holder_id
  end
end
