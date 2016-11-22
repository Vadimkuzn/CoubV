module Tasks
  class MassDestroyer

    def self.destroy(task_ids, user_id, klass)
      User.transaction do
        user = User.lock(true).find(user_id)
        reals_sum = klass.where(user_id: user_id).verified.where(id: task_ids).sum(:current_count)
        likes_sum = klass.where(user_id: user_id).not_verified.where(id: task_ids).sum(:current_count)

        klass.where(user_id: user_id).where(id: task_ids).update_all(deleted: true, current_count: 0, max_count: 0)

        
        user.add_reals(reals_sum * self.delete_coef(user)) if reals_sum > 0
        user.add_money(likes_sum * self.delete_coef(user)) if likes_sum > 0
      end
    end

    def self.delete_coef(user)
      user.is_premium? ? 1.0 : User::DELETE_TASK_KOEF
    end

  end
end
