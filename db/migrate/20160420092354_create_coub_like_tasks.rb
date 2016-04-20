class CreateCoubLikeTasks < ActiveRecord::Migration
  def change
    create_table :coub_like_tasks do |t|

      t.timestamps null: false
    end
  end
end
