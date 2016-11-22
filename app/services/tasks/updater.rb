module Tasks
  class Updater
    def self.update(klass, task_id, params, user_id, check_api_limits = false)
      User.transaction do
        user = User.lock(true).find(user_id)
        task = klass.unscoped.where(user_id: user_id).lock(true).find(task_id)

        raise ApiLimitExceeded if !task.verified && check_api_limits && !user.can_spend_api?(task.money_to_decrease_from_params(params))

        task.add_likes(params)
        task
      end
    end
  end
end
