class CreateCoubTasksUsers < ActiveRecord::Migration
  def change
    create_table :coub_tasks_users do |t|
      t.integer :user_id, null: false
      t.integer :coub_task_id, null: false
      t.string :coub_id, limit: 255, null: false
      t.boolean :state
      t.boolean :panished, default: false, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.timestamps null: false
    end
  end
end
