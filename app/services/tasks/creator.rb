module Tasks
  class Creator
    def self.create(task, user_id, verified, check_api_limits = false)
      User.transaction do
        user = User.lock(true).find(user_id)
        raise ApiLimitExceeded if !verified && check_api_limits && !user.can_spend_api?(task.money_to_decrease)

        task.user = user
        task.verified = verified if task.respond_to?(:verified)
        task.save!
      end
    end
  end
end
