class CreateLines < ActiveRecord::Migration[8.1]
  def change
    create_table :lines do |t|
      t.integer :code
      t.string :name
      t.string :color

      t.timestamps
    end
    add_index :lines, :code, unique: true
  end
end
