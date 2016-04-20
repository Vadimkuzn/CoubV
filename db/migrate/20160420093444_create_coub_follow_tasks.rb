class CreateCoubFollowTasks < ActiveRecord::Migration
  def change
    create_table :coub_follow_tasks do |t|

      t.timestamps null: false
    end
  end
end
