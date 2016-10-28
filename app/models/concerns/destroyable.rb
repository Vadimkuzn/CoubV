module Destroyable
  extend ActiveSupport::Concern
  
  included do
  	default_scope { where(deleted: false) }
  end

  def destroy
    money_to_return = (self.current_count * delete_coef).to_i

    self.deleted = true
    self.current_count = 0
    self.max_count = 0
    self.save(validate: false)

    if verified?
      self.user.add_reals(money_to_return) if money_to_return > 0
    else
      self.user.add_money(money_to_return) if money_to_return > 0
    end
  end

  def delete_coef
    user.is_premium? ? 1.0 : User::DELETE_TASK_KOEF
  end

end