module Pausable
  extend ActiveSupport::Concern
  included do
    scope :not_suspended, -> { where(suspended: false) }
    scope :suspended, -> { where(suspended: true) }

    scope :not_paused, -> { where(paused: false) }
    scope :paused, -> { where(paused: true) }
  end

  def pause!
  	self.paused = true
    self.save(:validate => false)
  end

  def unpause!
  	self.paused = false
    self.save(:validate => false)
  end

  def suspend!
    self.suspended = true
    self.save(:validate => false)
  end

  def unsuspend!
    self.suspended = false
    self.save(:validate => false)
  end

end