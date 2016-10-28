module CommonPayment
  extend ActiveSupport::Concern

  SALE_PERCENT = 0
  REALS_SALE_PERCENT = 0
  
  included do
    belongs_to :user
    belongs_to :task, :polymorphic => true
    belongs_to :promocode

    def self.is_likes_hit?(amount)
      amount == 999
    end

    def self.is_reals_hit?(amount)
      amount == 499
    end
  end
  
  
  module REASON
    LIKES = 1
    UNBAN = 2
    PREMIUM = 3
    CONCURS_HINT = 4
    REALS = 5
    QUICK_ORDER = 6
  end
  
  PRICES = {
    99 =>   600,
    199 =>  1500,
    499 =>  8000,
    999 =>  25000,
    2999 => 100000,
    4999 => 200000,
    9999 => 500000,
    14999 => 850000,
    19999 => 1400000,
    24999 => 2000000
  }

  REAL_PRICES = {
    99 => 200,
    199 => 450,
    499 => 2000,
    999 => 5000,
    2999 => 20000,
    4999 => 50000,
    9999 => 120000,
    14999 => 200000,
    19999 => 350000,
    24999 => 550000
  }
  
  def is_unban?
    self.reason == REASON::UNBAN
  end
  
  def is_premium?
    self.reason == REASON::PREMIUM
  end

  def is_hint?
    self.reason == REASON::CONCURS_HINT
  end
  
  def is_likes?
    self.reason == REASON::LIKES
  end

  def is_reals?
    self.reason == REASON::REALS
  end

  def is_quick_order?
    self.reason == REASON::QUICK_ORDER
  end
  
  def likes_to_add
    to_add = 0
    if self.promocode
      PRICES.each do |k, v|
        to_add += v if (self.amount - (k * discount_value).ceil).abs < 2
      end
    else
      hash_key = self.amount
      #puts "Likes to add(no promocode): hash_key = #{hash_key}"
      to_add = PRICES[hash_key]
      if to_add
        to_add += (to_add * (SALE_PERCENT + self.user.discount_bonus) / 100)
      end
    end
    to_add
  end

  def reals_to_add
    to_add = 0

    if self.promocode
      REAL_PRICES.each do |k, v|
        to_add += v if (self.amount - (k * discount_value).ceil).abs < 2
      end
    else
      hash_key = self.amount
      #puts "Reals to add(no promocode): hash_key = #{hash_key}"
      to_add = REAL_PRICES[hash_key]
      if to_add
        to_add += (to_add * (REALS_SALE_PERCENT + self.user.discount_bonus) / 100)
      end
    end
    to_add
  end
  
  protected
  def give_money_to_user
    if self.state == true
      if self.is_premium?
        process_premium
      elsif self.is_unban?
        process_unban
      elsif self.is_hint?
        process_hint
      elsif self.is_likes? #&& !PRICES[self.amount.to_i].nil?
        process_likes
      elsif self.is_reals? #&& !REAL_PRICES[self.amount.to_i].nil?
        process_reals
      elsif self.is_quick_order?
        self.task.current_count += self.task.ordered_cost_count(self.amount)
        self.task.save!(:validate => false)
      end
    end
  end

  def process_premium
    if self.promocode
      # puts "processing payment with promocode, amount: #{self.amount}"
      # puts "Discount for silver is: #{(PREMIUM_CONFIG['silver']['price'].to_i * discount_value).ceil}"
      # puts "Discount for gold is: #{(PREMIUM_CONFIG['gold']['price'].to_i * discount_value).ceil}"
      # puts "Discount for platinum is: #{(PREMIUM_CONFIG['platinum']['price'].to_i * discount_value).ceil}"
      # puts "Discount for ruby is: #{(PREMIUM_CONFIG['ruby']['price'].to_i * discount_value).ceil}"

      if (self.amount - (PREMIUM_CONFIG['silver']['price'].to_i * discount_value).ceil).abs < 2
        self.user.make_premium!(User::PREMIUM_KIND::SILVER)
      elsif (self.amount - (PREMIUM_CONFIG['gold']['price'].to_i * discount_value).ceil).abs < 2
        self.user.make_premium!(User::PREMIUM_KIND::GOLD)
      elsif (self.amount - (PREMIUM_CONFIG['platinum']['price'].to_i * discount_value).ceil).abs < 2
        self.user.make_premium!(User::PREMIUM_KIND::PLATINUM)
      elsif (self.amount - (PREMIUM_CONFIG['ruby']['price'].to_i * discount_value).ceil).abs < 2
        self.user.make_premium!(User::PREMIUM_KIND::RUBY)
      end
    else
      if self.amount == PREMIUM_CONFIG['silver']['price'].to_i
        self.user.make_premium!(User::PREMIUM_KIND::SILVER)
      elsif self.amount == PREMIUM_CONFIG['gold']['price'].to_i
        self.user.make_premium!(User::PREMIUM_KIND::GOLD)
      elsif self.amount == PREMIUM_CONFIG['platinum']['price'].to_i
        self.user.make_premium!(User::PREMIUM_KIND::PLATINUM)
      elsif self.amount == PREMIUM_CONFIG['ruby']['price'].to_i
        self.user.make_premium!(User::PREMIUM_KIND::RUBY)
      end
    end
  end

  def process_reals
    to_add = reals_to_add
    if to_add > 0
      User.where(['id = ?', self.user_id]).update_all(['reals = COALESCE(reals,0) + ?', to_add])
      if self.user.referral
        referral_reals = count_referral_reals(to_add)
        self.user.referral.add_referral_reals(referral_reals)
      end
    end
  end

  def process_likes
    #puts "Processing likes"
    to_add = likes_to_add
    if to_add > 0
      User.where(['id = ?', self.user_id]).update_all(['money = money + ?', to_add])
    end
  end

  def process_unban
    if self.user.unban_cost == self.amount
      user.money = 0 if user.ban_reason == User::BAN_REASON::CHEATER
      user.ban_reason = nil
      user.save
    end
  end

  def process_hint
    if self.amount.to_i == ConcursHint::COST
  #          puts "Amount is the same!"
      hint = ConcursHint.find(hint_id)
  #          puts "Hint found!"
      hint.pay!
  #          puts "Hint paid!"
    end
  end

  def discount_value
    (100 - self.promocode.discount).to_f / 100
  end

  def amount_with_discount
    (self.amount / discount_value).ceil - 1
  end

  def count_referral_reals(to_add)
    (to_add * User::REFERRAL_BUY_PERCENT / 100).to_i
  end

  
  def recount_user_payments
    self.user.count_payments_sum
  end
end
