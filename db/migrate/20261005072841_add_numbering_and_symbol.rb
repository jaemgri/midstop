class AddNumberingAndSymbol < ActiveRecord::Migration[8.1]
  def change
    add_column :stations, :numbering, :string
    add_column :lines, :symbol, :string
  end
end
