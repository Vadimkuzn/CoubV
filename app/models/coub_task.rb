class CoubTask < ActiveRecord::Base
 include Pausable
 include Destroyable
 include Lockable
 include Limitable
 include CommonTask

 TASK_LOCK_TIME = 25

 belongs_to :user

 before_validation :set_max_count

 default_scope { where(deleted: false) }

 def self.default_scope
  where deleted: false
 end

 def set_max_count
  self.max_count = self.cost.to_i * self.members_count.to_i
  self.current_count = self.max_count
 end

 def set_cost
  self.cost ||= 1
 end

 def self.get_existing(item_id, user_id, type, verified, deleted)
  CoubTask.unscoped.where(item_id: item_id, user_id: user_id, type: type.to_s, verified: verified, deleted: deleted).first
 end

 validates :title, presence: true, length: { maximum: 255 }
# validates :title, uniqueness: { case_sensitive: false }
 validates :members_count,  presence: true, numericality: { greater_than_or_equal_to: 10 }
 validates :cost,  presence: true, numericality: { greater_than_or_equal_to: 1,  less_than_or_equal_to: 15}

 validates :current_count,  presence: true
 validates :max_count,  presence: true, numericality: { greater_than_or_equal_to: 1 }
 validates :shortcode, presence: true
end
