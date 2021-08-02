class AddAutoRetestToClient < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :autoretest, :boolean, null: false, default: false
  end
end
