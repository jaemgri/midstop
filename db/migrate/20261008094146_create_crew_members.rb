class CreateCrewMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :crew_members do |t|
      t.references :crew, null: false, foreign_key: true
      t.integer :group_code, null: false
      t.string :name
      t.string :token
      t.timestamps
    end
    add_index :crew_members, :token, unique: true
  end
end
