class CreatePremium < ActiveRecord::Migration
  def up
    add_column :users, :premium_type, :string
    add_column :users, :premium_until, :datetime
  end

  def down
    remove_column :users, :premium_type
    remove_column :users, :premium_until
  end
end
