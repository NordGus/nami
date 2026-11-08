class CreatePadlockPasswords < ActiveRecord::Migration[8.1]
  def change
    create_table :padlock_passwords do |t|
      t.string :key, null: false
      t.belongs_to :holder, null: false, foreign_key: { to_table: :characters }
      t.belongs_to :replaced_by, null: true, foreign_key: { to_table: :padlock_passwords }
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :padlock_passwords, :expires_at
  end
end
