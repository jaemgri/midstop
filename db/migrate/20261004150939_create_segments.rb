class CreateSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :segments do |t|
      t.integer :line_code
      t.integer :from_code
      t.integer :to_code

      t.timestamps
    end
    add_index :segments, :line_code
    add_index :segments, :from_code
    add_index :segments, :to_code
  end
end
