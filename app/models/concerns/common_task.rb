module CommonTask
  extend ActiveSupport::Concern

  included do
    scope :verified, -> { where(verified: true) }
    scope :not_verified, -> { where(verified: false) }

    scope :finished, -> { where(finished: true) }
    scope :not_finished, -> { where(finished: false) }

    validates :cost, :numericality => { :only_integer => true, :greater_than => 0 }
    validates :members_count, :numericality => { :only_integer => true, :greater_than => 0 }
    validates :url, :presence => true
    validates :user_id, :presence => true
    validates :current_count, :numericality => { :only_integer => true }, :presence => true
    validates :max_count, :numericality => { :only_integer => true, :greater_than => 0 }
    validates :item_id, :presence => true

    before_validation :strip_bad_title_symbols
    before_validation :set_cost, on: :create
    before_validation :set_max_count, on: :create
#    before_validation :set_current_count, on: :create

    before_create :check_user_money
    before_create :check_money_to_decrease

    before_validation :strip_url

    after_create :decrease_user_money
  end

  def check!(u)
    result = task_completed?(u)
    result ? add_money_to_user(u) : mark_as_not_done(u)
    result
  end

  def decrease_user_money
    if verified?
      user.substract_reals(money_to_decrease)
    else
      user.substract_money(money_to_decrease)
    end
  end

  def check_user_money
    #puts "User.money = #{self.user.money}, User.reals = #{self.user.reals}"
    if verified?
      raise NoRealsException if user.reals < money_to_decrease
    else
      raise NoMoneyException if user.money < money_to_decrease
    end
    true
  end

  def check_money_to_decrease
    raise IncorrectMoneyToDecrease if money_to_decrease <= 0
    true
  end

  def user_bonus
    i_cost = cost.to_i
    res = i_cost

    if i_cost > 15
      res = i_cost - 5
    elsif i_cost > 10
      res = i_cost - 4
    elsif i_cost >= 8
      res = i_cost - 3
    elsif i_cost > 5
      res = i_cost - 2
    elsif i_cost >= 3
      res = i_cost - 1
    end
    res
  end

  def set_max_count
    self.max_count = money_to_decrease
  end

  def money_to_decrease
    members_count.to_i * real_cost
  end

  def money_to_decrease_from_params(task_params)
    cost = (task_params[:cost] || 1).to_i
    members_count = task_params[:members_count].to_i
    members_count.to_i * cost.to_i
  end

  def real_cost
    cost.to_i
  end

  def redirect_url
    NoRef.hide url
  end

  def strip_url
    url.strip!
  end

  def strip_bad_title_symbols
    self.title = title.strip.codepoints.select {|c| c < 50000}.pack("U*") unless title.blank?
  end

  def add_likes(task_params)
    assign_attributes(task_params)

    self.cost = (task_params[:cost] || 1).to_i
    self.members_count = task_params[:members_count].to_i

    check_money_to_decrease

    self.max_count += money_to_decrease
    self.url = task_params[:url] unless task_params[:url].blank?
    self.current_count += money_to_decrease
    self.deleted = false
    self.paused = false
    self.suspended = false

    check_user_money

    self.save!

    if verified?
      user.substract_reals(money_to_decrease)
    else
      user.substract_money(money_to_decrease)
    end
  end
end
