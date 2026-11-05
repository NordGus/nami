class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string :type, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :characters, :type
  end
end
