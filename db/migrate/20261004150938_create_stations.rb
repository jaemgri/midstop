class CreateStations < ActiveRecord::Migration[8.1]
  def change
    create_table :stations do |t|
      t.integer :code
      t.integer :group_code
      t.string :name
      t.string :name_romaji
      t.integer :line_code
      t.integer :pref_code
      t.float :lat
      t.float :lon

      t.timestamps
    end
    add_index :stations, :code, unique: true
    add_index :stations, :group_code
    add_index :stations, :line_code
  end
end
