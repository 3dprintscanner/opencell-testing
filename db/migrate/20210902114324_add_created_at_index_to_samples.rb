class AddCreatedAtIndexToSamples < ActiveRecord::Migration[6.1]
  def change
    add_index :samples, :created_at
  end
end
