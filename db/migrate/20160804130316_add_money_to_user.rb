class AddMoneyToUser < ActiveRecord::Migration
  def change
   add_column :users, :money, :integer, null:false, default: 0
  end
end
