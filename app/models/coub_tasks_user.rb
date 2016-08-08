class CoubTasksUser < ActiveRecord::Base
#  include Limitable

  belongs_to :user
  belongs_to :coub_task

  before_create :set_coub_id
  after_create  :decrease_task_money

  def set_coub_id
  	self.coub_id = self.user.uid
  end

  def decrease_task_money
    CoubTask.where(['id = ?', self.coub_task_id]).update_all(['current_count = current_count - ?', self.coub_task.real_cost]) if state != false
#    self.coub_task.increase_limit_counter
  end

end
