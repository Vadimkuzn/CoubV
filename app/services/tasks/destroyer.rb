module Tasks
  class Destroyer

    def self.destroy(task_id, user_id, klass)
      User.transaction do
        user = User.lock(true).find(user_id)
        task = klass.where(user_id: user_id).lock(true).find(task_id)
        task.destroy
        task
      end
    end


  end
end
