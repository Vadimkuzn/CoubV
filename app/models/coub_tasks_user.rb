class CoubTasksUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :coub_task

  before_create :set_coub_id
  after_create  :decrease_task_money

  def set_coub_id
  	provider = self.user.coub_provider
  	self.coub_id = provider.uid if provider
  end

  def decrease_task_money
    CoubTask.where(['id = ?', self.item_id]).update_all(['current_count = current_count - ?', self.coub_task.real_cost]) if state != false
    self.coub_task.increase_limit_counter
  end

end