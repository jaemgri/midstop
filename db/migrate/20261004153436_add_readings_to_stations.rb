class AddReadingsToStations < ActiveRecord::Migration[8.1]
  def change
    add_column :stations, :name_kana, :string
    add_column :stations, :search_key, :string
    add_index :stations, :search_key
  end
end
