class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :crew, null: false, foreign_key: true
      t.integer :group_code, null: false
      t.string :place_name, null: false
      t.string :genre
      t.string :budget
      t.string :url
      t.string :photo
      t.string :logged_by
      t.date :visited_on, null: false
      t.timestamps
    end
    add_index :visits, [:crew_id, :group_code, :place_name]
  end
end
