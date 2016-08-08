class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :auth_token
      t.string :name
      t.integer :money
      t.timestamps null: false
    end
  end
end
