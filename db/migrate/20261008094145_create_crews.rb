class CreateCrews < ActiveRecord::Migration[8.1]
  def change
    create_table :crews do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.timestamps
    end
    add_index :crews, :token, unique: true
  end
end
