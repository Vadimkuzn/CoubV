require 'timeout'
require 'digest/sha2'
require 'digest/md5'

class User < ActiveRecord::Base

  has_many :coub_tasks
  has_many :coub_like_tasks
  has_many :coub_follow_tasks

  def self.from_omniauth(auth)
   where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
    user.auth_token = auth.credentials.token
    user.name = auth.extra.raw_info.name
    user.save!
   end
  end

  def client
   @client ||= Faraday.new(:url => "http://coub.com/api/v2/", :params => {:access_token => auth_token})
  end

  acts_as_tagger
  has_shortened_urls

  attr_accessor :type, :token, :registration_ip, :registration_provider

  include Redis::Objects
  value :passed_captcha_at, expiration: 1.hour
  #counter :api_spent_likes

  PHONE_TRIES_COUNT = 3

  RECEIVE_LIKES_IN_MONTH = 25000

  REGISTRATIONS_PER_IP = 3

  USERS_PER_IP = 6
  REQUESTS_DELAY = 500

  IP_VERIFICATION_COUNT = 10

  INITIAL_MONEY = 0
  REFERRAL_MONEY = 10
  REFERRAL_BUY_PERCENT = 10
  REFERRAL_DO_PERCENT = 10

  REFFERAL_VERIFY_REALS = 25
  VERIFY_REALS_WITH_REFFERER = 25

  VIZIT_MONEY = 5
  VIZIT_REALS = 5
  PANISH_KOEF = 3
  DELETE_TASK_KOEF = 0.85
  TASK_LOGIN_TIME = 25

  MAX_TRANSACTIONS_PER_DAY = 3
  MAX_COUPONS_PER_DAY = 0

  include Authentication

  belongs_to :antibot_question

  has_many :bot_sessions, :inverse_of => :user
  has_many :bot_accounts, :inverse_of => :user

  has_one :running_bot_session, -> { where(state: BotSession::STATE::STARTED)}, :inverse_of => :user, :class_name => 'BotSession'

  has_many :coupons, :inverse_of => :user
  has_many :activated_coupons, :foreign_key => 'buyer_id', :class_name => 'Coupon', :inverse_of => :buyer

  has_many :notifications, -> { order('created_at desc') }

  has_many :fb_tasks, :inverse_of => :user
  has_many :fb_tasks_users, :inverse_of => :user

  has_many :ig_tasks, :inverse_of => :user
  has_many :ig_tasks_users, :inverse_of => :user
#  has_many :done_ig_tasks, through: :ig_tasks_users, class_name: 'IgTask'
#  has_many :not_done_ig_tasks, -> { where('ig_tasks_users.state = ?', false) }, through: :ig_tasks_users, class_name: 'IgTask'

  has_many :tw_tasks, :inverse_of => :user
  has_many :tw_tasks_users, :inverse_of => :user

  has_many :ok_tasks, :inverse_of => :user
  has_many :ok_tasks_users, :inverse_of => :user

  has_many :af_tasks, :inverse_of => :user
  has_many :af_tasks_users, :inverse_of => :user

  has_many :tasks, :inverse_of => :user
  has_many :tasks_users, :inverse_of => :user

  has_many :yt_tasks, :inverse_of => :user
  has_many :yt_tasks_users, :inverse_of => :user


  belongs_to :referral, :class_name => 'User'
  has_many :referrals, :class_name => 'User', :foreign_key => 'referral_id'
  has_many :verified_referrals, -> { where(verified: true) }, :class_name => 'User', :foreign_key => 'referral_id'

  has_many :trackings, :inverse_of => :user

  has_many :vkontakte_trackings, :class_name => 'VkontakteTracking', :inverse_of => :user
  has_many :vkontakte_repost_trackings, :class_name => 'VkontakteRepostTracking', :inverse_of => :user
  has_many :instagram_trackings, :class_name => 'InstagramTracking', :inverse_of => :user
  has_many :askfm_trackings, :class_name => 'AskfmTracking', :inverse_of => :user
  has_many :twitter_trackings, :class_name => 'TwitterTracking', :inverse_of => :user

  scope :verified, -> { where(verified: true) }

  before_save :ban_cheaters

  has_many :user_achievements, :inverse_of => :user
  has_many :achievements, :through => :user_achievements, :inverse_of => :user

  has_many :money_transactions, :foreign_key => 'from_id', :inverse_of => :from
  has_many :received_money_transactions, :foreign_key => 'to_id', :class_name => 'MoneyTransaction', :inverse_of => :from

  has_and_belongs_to_many :lotteries

  has_many :concurs_users, -> { order('concurs_users.created_at DESC') }

  has_many :user_providers, :inverse_of => :user
  has_many :battles, :inverse_of => :user

  validates_numericality_of :money #, :greater_than_or_equal_to => 0
  validate :check_phone

  before_validation :strip_bad_name_symbols

  before_create :set_initial_money
  before_create :set_auto_timestamps

  after_commit :give_money_to_referral, on: :create

  after_create :give_init_achievements
  after_create :create_vk_user_provider

  QUALITY_DO_TASK_MIN     = 80
  QUALITY_CREATE_TASK_MIN = 80
  QUALITY_PASS_LIKES_MIN  = 90
  MAX_QUALITY             = 100

  UNBAN_MINUTE_COST = 20

  CHAT_BAN_TIME = {
    5 => 100,
    10 => 200,
    20 => 350,
    60 => 1000,
    1440 => 15000,
    1440 * 7 => 75000
  }



  BONUS_HASH = {
      500 => 5,
      2500 => 10,
      5000 => 15,
      10000 => 20,
      25000 => 25
    }

  module BAN_REASON
    CHEATER = 1
    ADS = 2
    CHEATER_FRIEND = 3
    CLOSED_GROUP = 4
    FORBIDDEN_GROUP = 5
    OFTEN_BANS = 6
    USE_BAD_BOTS = 7
  end

  module PREMIUM_KIND
    SILVER = 'silver'
    GOLD = 'gold'
    PLATINUM = 'platinum'
    RUBY = 'ruby'
    VIP = 'vip'
  end

  API_LIKES_LIMIT = {
    PREMIUM_KIND::SILVER => 100000,
    PREMIUM_KIND::GOLD => 300000,
    PREMIUM_KIND::PLATINUM => 1000000,
    PREMIUM_KIND::RUBY => ""
  }


  UNBAN_COST = {
    BAN_REASON::CHEATER => 1250,
    BAN_REASON::FORBIDDEN_GROUP => 500,
    BAN_REASON::ADS => 100,
    BAN_REASON::CHEATER_FRIEND => 50,
    BAN_REASON::CLOSED_GROUP => 50,
    BAN_REASON::OFTEN_BANS => 500,
    BAN_REASON::USE_BAD_BOTS => 1500
  }

  module TODAY_LIMITS
    LIKES = 400
    GROUPS = 275
    COMMENTS = 200
    POLLS = 300
    FRIENDS = 50
    TELL_FRIENDS = 50
  end

  module VERIFIED_TODAY_LIMITS
    LIKES = 100
    GROUPS = 50
    COMMENTS = 50
    POLLS = 100
    FRIENDS = 50
    TELL_FRIENDS = 50
  end

  def unread_notifications
    self.notifications.where("created_at > ?", self.read_notifications_at)
  end

  def is_premium?
    self.premium_until != nil && self.premium_until > Time.now
  end

  def current_premium_type
     is_premium? ? premium_type : 'base'
  end

  def can_add_blacklist?
    self.moderator? || [120291, 336984, 97858, 121570, 555475, 2203195, 683089, 880861, 1192538, 1137409].include?(self.id)
  end

  def can_see_concurs?
    [192398263, 205836642].include?(self.vkontakte_id)
  end

  def can_create_coupon?(size = 1)
    coupons_created_today + size <= coupons_per_day
  end

  def api_spend!(amount)
    User.where(id: self.id).update_all(["api_spent_likes = COALESCE(api_spent_likes,0) + ?", amount])
    self.api_spent_likes = self.api_spent_likes.to_i + amount
    #api_spent_likes.increment(amount)
  end

  def can_spend_api?(amount)
    return false unless is_premium?
    return true if premium_type == PREMIUM_KIND::RUBY
    api_spent_likes.to_i + amount <= api_likes_limit
  end

  def api_likes_limit
    return 0 unless is_premium?
    return "∞" if premium_type == PREMIUM_KIND::RUBY
    API_LIKES_LIMIT[premium_type]
  end

  def reset_api_limits!
    self.update_column(:api_spent_likes, 0)
  end

  def coupons_per_day
    is_premium? ? PREMIUM_CONFIG[self.premium_type]['coupons_count'] : User::MAX_COUPONS_PER_DAY
  end

  def coupons_created_today
    self.coupons.where('created_at > ?', Date.today).count
  end

  alias :premium? :is_premium?

  def self.premium
    where('premium_until > ?', Time.now)
  end

  def self.quick
    User.find(User.quick_id)
  end

  def self.quick_id
    1
  end

  def can_mass_create_coupons?
    is_premium? && ['gold', 'platinum', 'ruby'].include?(premium_type)
  end

  def reset_likes_received!
    self.update_attribute(:likes_received, 0)
  end

  def locked_task_type?(type)
    $redis_pool.with do |redis|
      redis.get(lock_task_type_key(type)) != nil
    end
  end

  def self.create_from_omni_hash!(auth_hash, referral_id, remote_ip = nil)
#    User.create_from_omni_hash_impl(auth_hash, referral_id)
    return User.create_from_omni_hash_impl(auth_hash, referral_id) if remote_ip.blank?

    counter = Redis::Counter.new(User.reg_ip_key(auth_hash['provider'], remote_ip), expiration: 1.day)
    counter.increment do |val|
      raise TooManyUsersPerIp.new if val > REGISTRATIONS_PER_IP
      User.create_from_omni_hash_impl(auth_hash, referral_id, remote_ip)
    end
  rescue => ex
    puts "Error create from omni hash, hash: #{auth_hash.inspect}"
    raise ex
  end

  def self.create_from_omni_hash_impl(auth_hash, referral_id, remote_ip = nil)
    u = User.new
    u.name = auth_hash['info']['name']
    u.avatar_path = auth_hash['info']['image']
    u.referral_id = referral_id
    u.registration_ip = remote_ip
    u.registration_provider = auth_hash['provider']
    u.save!
    u
  end

  def self.reg_ip_key(provider, remote_ip)
    "reg-#{provider}-#{remote_ip}"
  end

  def lock_task_type!(type, redis = nil, period = nil)
    if redis
      redis.setex(lock_task_type_key(type), period || CLIENT_CONFIG[:vk][:delays][:do][type].to_i, Time.now.to_i)
    else
      $redis_pool.with do |redis|
        redis.setex(lock_task_type_key(type), period || CLIENT_CONFIG[:vk][:delays][:do][type].to_i, Time.now.to_i)
      end
    end
  end

  def unlock_task_type!(type)
    $redis_pool.with do |redis|
      redis.del(lock_task_type_key(type))
    end
  end


  def verificate!(code, ip, verif_uniq_code)
    if self.code.to_s == code.to_s
      verificate_no_check!(ip, verif_uniq_code)
      return true
    end
    false
  end

  def generate_verification_code
    code = ''
    5.times {code += (0..9).to_a.sample.to_s}
    code
  end


  def save_verification_code!(code, phone)
    self.phone = phone
    self.code = code
    self.phone_tries = (self.phone_tries || 0) + 1
    self.save!
  end

  def reset_code!
    self.code = nil
    self.phone = nil
    self.save!
  end

  def phone_tries_exceeded?
    phone_tries && phone_tries >= PHONE_TRIES_COUNT
  end

  def check_phone
    errors.add(:phone, 'Invalid format') if !self.phone.blank? && !User.is_phone_format_correct?(self.phone)
  end

  def verificate_no_check!(ip = nil, verif_uniq_code = nil)
    self.verified = true
    self.verification_ip = ip
    self.verif_uniq_code = verif_uniq_code
    self.save!

    if self.referral
      self.add_reals(User::VERIFY_REALS_WITH_REFFERER)
      self.referral.add_referral_reals(User::REFFERAL_VERIFY_REALS)

      self.referral.verified_referrals_count += 1
      self.referral.save!
    else
      self.add_reals(User.start_reals_amount)
    end
    self.give_init_real_achievements
  end

  def self.start_reals_amount
    10
  end

  def recount_earned_reals_by_referrals!
    verified_referrals = User.where(:referral_id => self.id).joins(:user_providers).where('user_providers.verified = ?', true).all
    reals_from_verification = verified_referrals.count * VERIFY_REALS_WITH_REFFERER

    self.reals_earned_referrals = reals_from_verification
    self.save!
  end

  def verification_tries_count(social_name)
    up = UserProvider.get_by_user(social_name, self.id)
    up.phone_tries || 0
  end

  def self.phone_busy?(name, phone)
    User.where(:phone => phone, :verified => true).exists?
  end

  def self.ip_used?(ip)
    return false if ip.blank? || true
    User.where(:verification_ip => ip).count >= User::IP_VERIFICATION_COUNT
  end

  def self.is_phone_format_correct?(phone)
    #((phone =~ /((7)|(380|375|372|995))\d+\z/) == 0)
    (phone =~ /\A\d+\z/) == 0
  end

  def verification_code_key
    "users-verif-code-#{self.id}"
  end

  def lock_task_type_key(type)
    "lock_task_#{type}-#{self.id}"
  end

  def self.get_by_remember_token(rt)
    res = Rails.cache.fetch(rt_cache_key(rt), :expires_in => 120) do
      User.find_by_remember_token(rt)
    end
  end

  def self.remember_login_task(social_name, social_id, task_id)
    $redis_pool.with do |redis|
      redis.setex(login_task_key(social_name, social_id), TASK_LOGIN_TIME, task_id)
    end
  end

  def self.get_login_task(social_name, social_id)
    $redis_pool.with do |redis|
      redis.get(login_task_key(social_name, social_id))
    end
  end

  def self.login_task_key(social_name, social_id)
    "login-task-#{social_name}-#{social_id}"
  end

  def self.get_by_client_token(ct)
    return nil if ct.blank?

    res = Rails.cache.fetch(ct_cache_key(ct), :expires_in => 180) do
      User.find_by_client_token(ct)
    end
  end

  def update_in_cache!
    Rails.cache.write(User.rt_cache_key(remember_token), self, expires_in: 120)
  end

  def update_in_cache_by_client!
    Rails.cache.write(User.ct_cache_key(client_token), self, expires_in: 120)
  end

  def self.rt_cache_key(rt)
    "rt-#{rt}"
  end

  def self.ct_cache_key(ct)
    "ct-#{ct}"
  end

  def rt_cache_key
    User.rt_cache_key(remember_token)
  end

  def ct_cache_key
    User.ct_cache_key(client_token)
  end

  def trackings_max_count
    is_premium? ? PREMIUM_CONFIG[premium_type]['trackings_count'].to_i : 0
  end

  def can_add_askfm_tracking?
    askfm_trackings.count < trackings_max_count
  end

  def can_add_twitter_tracking?
    twitter_trackings.count < trackings_max_count
  end

  def can_add_vkontakte_tracking?
    self.vkontakte_trackings.count + self.vkontakte_repost_trackings.count < self.trackings_max_count
  end

  def can_add_instagram_tracking?
    instagram_trackings.count < trackings_max_count
  end

  def facebook_bind?
    up = facebook_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def sold_likes_to
    passed_to = MoneyTransaction.where(from_id: id).uniq.pluck(:to_id)
    from_coupons = Coupon.activated.where(user_id: id).uniq.pluck(:buyer_id)
    all_users = passed_to + from_coupons
    all_users.uniq!

    User.where(id: all_users).all
  end

  def self.referral_concurs_top
    User.select("(select count(0) from users as su where su.referral_id = users.id AND su.created_at >= '#{Concurs::START_DATE}' AND(su.earned_reals >= #{Concurs::EARN_REALS} OR su.verified_referrals_count >= #{Concurs::VERIFIED_REFERRALS_COUNT} OR su.payments_sum > 0)) AS referrals_total, users.*").verified.order('referrals_total desc').limit(25).all
  end

  def vkontakte_bind?
    vkontakte_provider != nil
  end

  def instagram_bind?
    up = instagram_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def youtube_bind?
    up = youtube_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def twitter_bind?
    up = twitter_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def odnoklassniki_bind?
    up = odnoklassniki_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def odnoklassniki_api_bind?
    up = odnoklassniki_api_provider
    up.nil? || up.access_token.nil? ? false : true
  end

  def askfm_bind?
    askfm_provider != nil
  end

  def odnoklassniki_provider
    @odnoklassniki_provider ||= UserProvider.get_by_user(:odnoklassniki, id)
  end

  def odnoklassniki_api_provider
    @odnoklassniki_api_provider ||= UserProvider.get_by_user(:odnoklassniki_api, id)
  end

  def askfm_provider
    @askfm_provider ||= UserProvider.get_by_user(:askfm, id)
  end

  def youtube_provider
    @youtube_provider ||= UserProvider.get_by_user(:youtube, id)
  end

  def twitter_provider
    @twitter_provider ||= UserProvider.get_by_user(:twitter, id)
  end

  def facebook_provider
    @facebook_provider ||= UserProvider.get_by_user(:facebook, id)
  end

  def vkontakte_provider
    @vkontakte_provider ||= UserProvider.get_by_user(:vkontakte, id)
  end

  def instagram_provider
    @instagram_provider ||= UserProvider.get_by_user(:instagram, id)
  end

  def facebook_id
    facebook_provider.uid
  end

  def update_providers_counter!
    self.providers_count = UserProvider.where(:user_id => self.id).count
    self.save(:validate => false)
  end

  def increase_quality!(task)
    User.where(:id => self.id).update_all(['quality = quality + ?', task.quality_cost]) if self.quality < 100
  end

  def add_money(m, increase_received_likes = false)
    if self.id == 1451321
      BUG_LOGGER.error "Adding likes: #{m}, trace:"
      begin
        raise "bug"
      rescue => ex
        BUG_LOGGER.error ex.backtrace.join('\n')
      end
    end

    to_add = m.round
    if increase_received_likes
      User.where(:id => self.id).update_all(['money = money + ?, likes_received = COALESCE(likes_received,0) + ?', to_add, to_add])
    else
      User.where(:id => self.id).update_all(['money = money + ?', to_add])
    end
  end

  def add_referral_reals(referral_reals)
    User.where(:id => self.id).update_all(['reals = COALESCE(reals,0) + ?, reals_earned_referrals = reals_earned_referrals + ?', referral_reals, referral_reals])
  end

  def add_referral_likes(referral_likes)
    if self.id == 1451321
      BUG_LOGGER.error "Adding REFFERAL likes : #{m}, trace:"
      begin
        raise "bug"
      rescue => ex
        BUG_LOGGER.error ex.backtrace.join('\n')
      end
    end
    User.where(:id => self.id).update_all(['money = money + ?, likes_earned_referrals = likes_earned_referrals + ?', referral_likes, referral_likes])
  end

  def add_reals(r)
    User.where(:id => self.id).update_all(['reals = COALESCE(reals,0) + ?', r.round])
  end

  def add_reals_for_task(r)
    User.where(:id => self.id).update_all(['reals = COALESCE(reals,0) + ?, earned_reals = COALESCE(earned_reals,0) + ?', r.round, r.round])
  end

  def add_money_and_reals(m, r)
    User.where(:id => self.id).update_all(['money = money + ?, reals = COALESCE(reals,0) + ?', m.round, r.round])
  end

  def substract_money(m)
    User.where(:id => self.id).update_all(['money = money - ?', m.round])
  end

  def substract_reals(r)
    User.where(:id => self.id).update_all(['reals = reals - ?', r.round])
  end

  def give_money_for_task!(t, done_count = 1)
    if t.verified?
      self.add_reals_for_task(done_count * t.user_bonus)
    else
      self.add_money(done_count * t.user_bonus)
    end
    #self.update_in_cache!
  end

  def forget_quality_cost(task)
    is_premium? ? PREMIUM_CONFIG[premium_type]['forget_quality_cost'].to_i : 500
  end

  def generate_client_token!(salt = '')
    self.client_token = Digest::MD5.hexdigest("vk_sucks-#{self.id}-many-#{salt}many-times")
    self.save!
  end

#  def can_do_bot_tasks?(type)
#    return false unless can_do_task?
#
#    #actual_limits = Redis.current.getm(lock_task_type_key(type), )
#
#    @user.locked_task_type?(type) || @user.limit_exceeded_for?(type)
#  end

  def can_do_task?
    quality >= QUALITY_DO_TASK_MIN
    #true
  end

  def can_create_task?
    quality >= QUALITY_CREATE_TASK_MIN
    #true
  end

  def quality_tasks
    Task.unscoped.joins(:tasks_users).where('tasks_users.panished = ?', true).where('tasks_users.user_id = ?', self.id).limit(10).order('cost desc')
  end

  def ig_quality_tasks
    IgFollowTask.unscoped.joins(:ig_tasks_users).where('ig_tasks_users.panished = ?', true).where('ig_tasks_users.user_id = ?', self.id).limit(10).order('cost desc')
  end

  def chat_long_ago_registred?
    self.created_at < 1.day.ago
  end

  def self.my_account
    User.find_by_vkontakte_id(192398263)
  end

  def twitter_bound?
    self.twitter_token && self.twitter_name && self.twitter_id && self.twitter_secret
  end

  def self.generate_status_auth(user_id, key = :vk)
    AUTH_STATUSES[key].sample
  end


  def self.remember_status_auth(user_id, status, provider = 'vk')
    $redis_pool.with do |redis|
      redis.setex(User.auth_status_key(user_id, provider), 300, status)
    end
  end

  def self.get_status_auth(user_id, provider = 'vk')
    $redis_pool.with do |redis|
      redis.get(User.auth_status_key(user_id, provider))
    end
  end

  def self.remember_ig_login_task(ig_user_id, task)
    $redis_pool.with do |redis|
      redis.setex(User.ig_login_task_key(ig_user_id), 300, task.id)
    end
  end

  def self.remember_tw_login_task(tw_user_id, task)
    $redis_pool.with do |redis|
      redis.setex(User.tw_login_task_key(tw_user_id), 300, task.id)
    end
  end

  def self.get_tw_login_task(tw_user_id)
    $redis_pool.with do |redis|
      redis.get(User.tw_login_task_key(tw_user_id))
    end
  end


  def self.get_ig_login_task(ig_user_id)
    $redis_pool.with do |redis|
      redis.get(User.ig_login_task_key(ig_user_id))
    end
  end

  def self.ig_login_task_key(ig_user_id)
    "ig-login-task-#{ig_user_id}"
  end

  def self.tw_login_task_key(tw_user_id)
    "tw-login-task-#{tw_user_id}"
  end

  def make_premium!(premium_kind)
    premium_length = 31.days
    #premium_length = 37.days
    #premium_length = 62.days
    #premium_length = 46.days

    if is_premium? && self.premium_type == premium_kind
      self.premium_until += premium_length
      self.save! if self.give_vizit_money == 0  # saves object
    else
      self.premium_type = premium_kind
      self.premium_until = Time.now + premium_length
      self.save! if self.give_vizit_money == 0  # saves object
    end
    self.verificate_no_check! if !self.verified?

  end

  def reset_twitter!
    self.twitter_id = self.twitter_name = self.twitter_token = self.twitter_secret = nil
    self.save!
  end

  def maximum_transfer_amount
    is_premium? ? PREMIUM_CONFIG[premium_type]['money_transaction_max_amount'].to_i : MoneyTransaction::MAXIMUM_AMOUNT
  end

  def transfer_money_comission
    is_premium? ? PREMIUM_CONFIG[premium_type]['pass_likes_comission'].to_i : MoneyTransaction::COMISSION
  end

  def chat_banned?
    self.chat_ban_until && self.chat_ban_until > Time.now
  end

  def self.chat_ip_banned?(ip)
    $redis_pool.with do |redis|
      redis.exists(User.chat_ip_key(ip))
    end
  end

  def self.ban_chat_ip!(ip)
    $redis_pool.with do |redis|
      redis.setex(User.chat_ip_key(ip), 60 * 60 * 24, 'a') unless ip.blank? && MY_IPS.include?(ip)
    end
  end

  def self.chat_ip_key(ip)
    "chat-ip-#{ip}"
  end

  def can_ban_in_chat?
    moderator? #|| !chat_banned?
  end

  def can_ban_by_ip_in_chat?
    [46587, 65230, 462524, 178829].include?(self.id)
  end

  def can_delete_chat_messages?
    moderator? #[46587].include?(self.id)#
  end

  def chat_unban_cost
    (((self.chat_ban_until - Time.now) / 60).to_i + 1) * UNBAN_MINUTE_COST
  end

  def unban_chat!
    fixed_unban_cost = chat_unban_cost

    if self.money < fixed_unban_cost
      raise I18n.t('users.no_money')
    end

    self.substract_money(fixed_unban_cost)

    self.chat_ban_until = nil
    self.save!
  end

  def can_be_banned_in_chat?
    !moderator?
  end

  def free_chat_messages?
    self.is_premium? || self.moderator?
  end

  def chat_ban_price_koef
    self.moderator? ? 0 : 1
  end

  def ban_chat_user!(u, period)
    unless can_ban_in_chat?
      raise I18n.t('chat.cannot_ban')
    end

    money_to_decrease = CHAT_BAN_TIME[period.to_i]

    if money_to_decrease.nil?
      return nil
    end
    money_to_decrease = money_to_decrease * self.chat_ban_price_koef

    if self.money < money_to_decrease
      raise I18n.t('users.no_money')
    end

    User.transaction do
      self.substract_money(money_to_decrease)
      u.ban_chat!(period)
    end

    return true
  end



  def self.suspicious
    susp = []
    User.where('money > 10000').each { |u|
      susp << u if u.is_suspicious?
    }
    susp
  end

  def print_stats
    money_transactions_sum = MoneyTransaction.where(:to_id => self.id).sum(&:amount_to)
    lotteries_sum = self.lotteries.where(:winner_id => self.id).sum(&:bank)
    auctions_sum = Auction.where(:finished => true, :last_user_id => self.id).sum(&:bank)
    battles_sum = Battle.where(:winner_id => self.id).all.sum(&:prize)
    payed_sum = self.payments_sum > 0 ? SprypayPayment.includes(:user).where(:state => true).where(:user_id => self.id).where(:reason => SprypayPayment::REASON::LIKES).sum(&:likes_to_add) : 0
    tasks_sum = Task.unscoped.where(:user_id => self.id).sum(:max_count)
    tasks_done = TasksUser.where(:user_id => self.id, :state => true).count
    referrals_sum = self.referrals_count * REFERRAL_MONEY

    puts "Name: #{self.name}"
    puts "Money: #{self.money}"
    puts "Tasks_sum: #{tasks_sum}"
    puts "Tasks_done: #{tasks_done}"
    puts "Money transactions: #{money_transactions_sum}"
    puts "Referrals: #{referrals_sum}"
    puts "Lotteries: #{lotteries_sum}"
    puts "Auctions: #{auctions_sum}"
    puts "Battles: #{battles_sum}"
    puts "Payed: #{payed_sum}"
  end

  def is_suspicious?
    money_transactions_sum = MoneyTransaction.where(:to_id => self.id).sum(&:amount_to)
    lotteries_sum = self.lotteries.where(:winner_id => self.id).sum(&:bank)
    auctions_sum = Auction.where(:finished => true, :last_user_id => self.id).sum(&:bank)
    battles_sum = Battle.where(:winner_id => self.id).all.sum(&:prize)
    payed_sum = self.payments_sum > 0 ? SprypayPayment.includes(:user).where(:state => true).where(:user_id => self.id).where(:reason => SprypayPayment::REASON::LIKES).sum(&:likes_to_add) : 0
    referrals_sum = self.referrals_count * REFERRAL_MONEY
    tasks_sum = Task.unscoped.where(:user_id => self.id).sum(:max_count)

    tasks_done = TasksUser.where(:user_id => self.id, :state => true).count

    all_sum = money_transactions_sum + lotteries_sum + auctions_sum + battles_sum + payed_sum + referrals_sum

    self.money + tasks_sum > all_sum && tasks_done < 30 && tasks_done > 0
  end

  def can_receive_likes?(amount)
    is_premium? ? true : ((self.likes_received || 0) + amount.to_i) <= RECEIVE_LIKES_IN_MONTH
  end

  def can_get_passed_likes?
    verified? || is_premium? || created_at <= 1.day.ago
  end

  def ban_chat!(period)
    if chat_banned?
      self.chat_ban_until += period.to_i.minutes
    else
      self.chat_ban_until = Time.now + period.to_i.minutes
    end
    save!
  end

  def ban!(reason)
    ban_one!(reason)

    if reason == BAN_REASON::CHEATER || BAN_REASON::USE_BAD_BOTS
      self.money = 0
      self.save

      # Task.unscoped.where(:user_id => self.id).all.each { |t|
      #   t.deleted = true
      #   t.current_count = 0
      #   t.save(:validate => false)
      # }
    end

#    if reason == BAN_REASON::CHEATER
#      self.money_transactions.all.each { |t|
#        t.to.ban!(BAN_REASON::CHEATER_FRIEND) unless t.to.banned?
#      }

#      MoneyTransaction.where(:to_id => self.id).all.each { |t|
#        t.from.ban!(BAN_REASON::CHEATER_FRIEND) unless t.from.banned?
#      }
#    end
  end

  def ban_one!(reason)
    self.ban_reason = reason
    #self.money = 0
    self.save!

    Task.unscoped.where(:user_id => self.id).all.each { |t|
      t.paused = true
      t.save(:validate => false)
#      t.update_attribute(:current_count, 0)
    }
  end

  def banned?
    ban_reason != nil && ban_reason != 0
  end

  def self.banned
    where('ban_reason IS NOT NULL AND ban_reason > 0')
  end

  def self.remember_request_by_ip!(ip, user_id)
    return if ip.blank? || MY_IPS.include?(ip)

    key = ip_key(ip)
    $redis_pool.with do |redis|
      res = redis.lrange(key, 0, -1)
      unless res.blank?
        return if res.include?(user_id.to_s)
        if res.count < USERS_PER_IP
          redis.lpush(key, user_id)
        else
          raise TooManyUsersPerIp
        end
      else
        redis.multi do
          redis.lpush(key, user_id)
          redis.expire(key, 6 * 60 * 60)
        end
      end
    end
  end

  def self.remember_request_by_id!(user_id, controller, action)
    key = id_key(user_id, controller, action)
    $redis_pool.with do |redis|
      res = redis.get(key)
      unless res.blank?
        raise TooManyRequestsPerUser if (convert_request_time(Time.now) - res.to_i) < REQUESTS_DELAY
        redis.set(key, convert_request_time(Time.now))
      else
        redis.setex(key, 300, convert_request_time(Time.now))
      end
    end
  end

  def self.convert_request_time(t)
    (t.to_f * 1000).to_i
  end

  def self.id_key(id, controller, action)
    "#{controller}-#{action}-#{id}"
  end

  def self.ip_key(ip)
    "ips-#{ip}"
  end

  def limits_today
    return @limits_today_impl if @limits_today_impl

    key = limits_key
    $redis_pool.with do |redis|
      res = redis.hgetall(key)
      if res.nil? || res.empty?
        create_limits(key, redis)
        res = redis.hgetall(key)
      end
      @limits_today_impl = res
    end
  end

  def self.reset_limits!
    User.where('gave_vizit_money_at > ?', 4.days.ago).find_each do |user|
      user.reset_limit!
    end
  end

  def reset_limit!
    $redis_pool.with do |redis|
      redis.expire(limits_key, 5)
    end
  end

  def is_auction_last_winner?(auction)
    $redis_pool.with do |redis|
      if auction.kind == Auction::KIND::STANDARD
        return redis.lrange(Auction::WINNERS_KEY, 0, Auction::LAST_WINNERS_COUNT - 1).include?(self.id.to_s)
      else
        return redis.lrange(Auction::WINNERS_REALS_KEY, 0, Auction::LAST_WINNERS_COUNT - 1).include?(self.id.to_s)
      end
    end
  end

  def likes_today
    today_limit_impl(:likes)
  end

  def groups_today
    today_limit_impl(:groups)
  end

  def polls_today
    today_limit_impl(:polls)
  end

  def comments_today
    today_limit_impl(:comments)
  end

  def friends_today
    today_limit_impl(:friends)
  end

  def limit_exceeded_for?(type)
    self.send("#{type}_limit_exceeded?")
  end

  def create_vk_user_provider
    UserProvider.create!(:name => :vkontakte, :uid => self.vkontakte_id, :user_id => self.id) if self.vkontakte_id
  end

  def self.richiest(c = 20)
    order('money desc').limit(c)
  end

  def can_pass_likes?
    self.money > 0 && self.money_transactions_today < self.allowed_money_transactions_today && self.quality >= QUALITY_PASS_LIKES_MIN
  end

  def pass_likes!(to_user, amount)
    return 0 if !can_pass_likes? || self.money < MoneyTransaction.new(from: self).minimum_amount
    MoneyTransaction.create!(:from => self, :to => to_user, :amount_from => amount)
    self.update_in_cache_by_client!
    amount
  end

  def money_transactions_today
    self.money_transactions.for_today.count
  end

  def allowed_money_transactions_today
    is_premium? ? PREMIUM_CONFIG[premium_type]['money_transactions_count'].to_i : MAX_TRANSACTIONS_PER_DAY
  end

  def got_vizit_money_today?
    return false if self.gave_vizit_money_at == nil
    return true if self.locked_vizit_money?
    self.gave_vizit_money_at > Date.today.to_time.in_time_zone
  end

  def update_counters!
    current_user = self
    self.referrals_count = self.referrals.count
    self.likes_count =  TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::LIKES, true).count
    self.groups_count =  TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::ADD_TO_GROUP, true).count
    self.tell_friends_count = TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::TELL_FRIENDS, true).count
    self.add_friends_count = TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::ADD_FRIENDS, true).count
    self.comments_count = TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::COMMENTS, true).count
    self.polls_count = TasksUser.joins('join tasks ON tasks.id = tasks_users.task_id').where('tasks_users.user_id = ? AND tasks.kind = ? AND tasks_users.state = ?', current_user.id, Task::KIND::POLL, true).count
    self.panishments_count = TasksUser.where('panished = ? AND user_id = ?', true, current_user.id).count
    self.save
  end

  def give_vizit_money
    return 0 if locked_vizit_money?
    if !self.verified? && self.providers_count == 1 && !self.premium? && !self.twitter_provider.nil?
      self.gave_vizit_money_at = Time.now
      self.save
      return 0
    end
    lock_vizit_money!

    self.gave_vizit_money_at = Time.now
    self.read_notifications_at ||= Time.now
    self.save

    money_to_add = get_vizit_money_amount
    reals_to_add = get_vizit_reals_amount
    self.add_money_and_reals(money_to_add, reals_to_add)

    return money_to_add, reals_to_add
  end

  def lock_vizit_money!
    $redis_pool.with do |redis|
      redis.setex(vizit_money_lock_key, 5 * 60, Time.now)
    end
  end

  def locked_vizit_money?
    $redis_pool.with do |redis|
      redis.exists(vizit_money_lock_key)
    end
  end

  def vizit_money_lock_key
    "vizit-money-#{self.id}"
  end

  def bet?(lottery)
    LotteriesUser.where(:user_id => self.id, :lottery_id => lottery.id).count != 0
  end

  def got_money_for_likes_today?
    return false if self.gave_money_for_no_likes_at == nil
    self.gave_money_for_no_likes_at > Date.today.to_time.in_time_zone
  end

#  def panishments_count
#    TasksUser.where(:panished => true).where(:user_id => self.id)
#  end

  def panishments_sum
    TasksUser.joins('JOIN tasks ON tasks.id = task_id').where(:panished => true).where('tasks_users.user_id = ?', self.id).sum('tasks.cost').to_i * PANISH_KOEF
  end

  def panishments_today_sum
    TasksUser.joins('JOIN tasks ON tasks.id = task_id').where(:panished => true).where('tasks_users.user_id = ?', self.id).where('tasks_users.created_at > ?', Date.today).sum('tasks.cost').to_i * PANISH_KOEF
  end

  def add_achievement(a)
    if a
      UserAchievement.create(:achievement => a, :user => self)
#      self.update_attribute(:last_achievement_order, a.number)
    end
  end

  def need_refresh_turbo?
    bind_desktop_at < 3.days.ago
  end

  def discount_bonus
    current_bonus = 0
    if payments_sum > 0
      BONUS_HASH.each_pair { |rubles, percent|
        if payments_sum >= rubles
          current_bonus = percent
        end
      }
    end
    current_bonus
  end

  def paid_for_lottery_today?
    lottery_payment_at != nil && (lottery_payment_at + 4.hours) > Date.today
  end

  def bind_desktop_token?
    self.desktop_token != nil
  end

  def self.with_desktop_token
    where('desktop_token is not null')
  end

  def likes_limit_exceeded?
    #current_limits = UserLimitsLoader.new(:vk).load_limits
    likes_today >= today_likes_limit
  end

  def tell_friends_limit_exceeded?
    false
  end

  def friends_limit_exceeded?
    friends_today >= today_friends_limit
  end

  def groups_limit_exceeded?
    groups_today >= today_groups_limit

  end

  def invites_limit_exceeded?
    false
  end

  def polls_limit_exceeded?
    false
    #polls_today >= TODAY_LIMITS::POLLS
  end

  def comments_limit_exceeded?
    false
    #comments_today >= TODAY_LIMITS::COMMENTS
  end

  def visits_limit_exceeded?
    false
    #comments_today >= TODAY_LIMITS::COMMENTS
  end

  def today_likes_limit
    verified? ? VERIFIED_TODAY_LIMITS::LIKES : TODAY_LIMITS::LIKES
  end

  def today_groups_limit
    verified? ? VERIFIED_TODAY_LIMITS::GROUPS : TODAY_LIMITS::GROUPS
  end

  def today_friends_limit
    verified? ? VERIFIED_TODAY_LIMITS::FRIENDS : TODAY_LIMITS::FRIENDS
  end

  def today_tell_friends_limit
    verified? ? VERIFIED_TODAY_LIMITS::TELL_FRIENDS : TODAY_LIMITS::TELL_FRIENDS
  end

  def today_comments_limit
    verified? ? VERIFIED_TODAY_LIMITS::COMMENTS : TODAY_LIMITS::COMMENTS
  end

  def today_polls_limit
    verified? ? VERIFIED_TODAY_LIMITS::POLLS : TODAY_LIMITS::POLLS
  end

  def self.auth_status_key(user_vk_id, provider = 'vk')
    "#{provider}-users-auth-status-#{user_vk_id}"
  end

  def self.get_status(user_vk_id)
    status = nil
    3.times {
      status = Vkontakte.get_status(CHECKER_TOKEN, user_vk_id) rescue nil
      #status = Vkontakte.get_status(User.my_account.desktop_token, user_vk_id) if status.blank?
      break unless status.blank?
      #sleep 1
    }
    #status = RestClient.get(vk_url) if status.blank?
    status
  end



  def set_like(task)
    if likes_limit_exceeded? || task.limit_exceeded?
      return nil
    end

    begin
      return Timeout::timeout(2) {
        res = Vkontakte.add_like(self.desktop_token, task.item_type, task.item_owner, task.item_id, true)
        increase_likes_limit_counter
        res
      }
    rescue Vkontakte::InvalidTokenException
      self.desktop_token = nil
      self.bind_desktop_at = nil
      self.save
      return nil
    rescue Vkontakte::ItemNotFoundException
      #task.pause!
      return nil
    rescue
      return nil
    end
  end

  def add_vote(task)
    if polls_limit_exceeded? || task.limit_exceeded?
      return nil
    end

    begin
      return Timeout::timeout(2) {
        res = Vkontakte.add_vote(self.desktop_token, task.item_owner, task.item_id, task.item_answer_id, true)
        increase_polls_limit_counter
        res
      }
    rescue Vkontakte::InvalidTokenException
      self.desktop_token = nil
      self.bind_desktop_at = nil
      self.save
      return nil
    rescue Vkontakte::ItemNotFoundException
      #task.pause!
      return nil
    rescue
      return nil
    end
  end

  def add_group(group_id)
    if groups_limit_exceeded?
      return nil
    end

    begin
      return Timeout::timeout(2) {
        res = Vkontakte.add_group(self.desktop_token, group_id, true)
        increase_groups_limit_counter
        res
      }
    rescue Vkontakte::InvalidTokenException
      self.desktop_token = nil
      self.bind_desktop_at = nil
      self.save
      return nil
    rescue Vkontakte::ItemNotFoundException
#      task.update_attribute(:deleted, true)
      return nil
    rescue
      return nil
    end
  end

  def add_friend(user_id)
    if friends_limit_exceeded?
      return nil
    end

    begin
      return Timeout::timeout(2) {
        res = Vkontakte.add_friend(self.desktop_token, user_id, true)
        increase_friends_limit_counter
        res
      }
    rescue Vkontakte::InvalidTokenException
      self.desktop_token = nil
      self.bind_desktop_at = nil
      self.save
      return nil
    rescue Vkontakte::ItemNotFoundException
#      self.update_attribute(:deleted, true)
      return nil
    rescue
      return nil
    end
  end

  def increase_likes_limit_counter
    increase_limit_counter(:likes)
  end

  def increase_groups_limit_counter
    increase_limit_counter(:groups)
  end

  def increase_polls_limit_counter
    increase_limit_counter(:polls)
  end

  def increase_friends_limit_counter
    increase_limit_counter(:friends)
  end

  def increase_comments_limit_counter
    increase_limit_counter(:comments)
  end

  def paid_for_auction_today?
    auction_payment_at != nil && (auction_payment_at + 4.hours) > Date.today
  end

  def next_achievement(a)
    Achievement.where('number > ? AND kind = ?', a.number, a.kind).first
  end

  def process_achievement(kind, count = 1)
    user_achievements = UserAchievement.joins(:achievement).where('kind = ? AND user_id = ? AND done = ?', kind, self.id, false).readonly(false).all
    result = []
    user_achievements.each { |ua|
      res = ua.process(count)
      result << res if res
    }
    return result
  end

  def give_init_achievements
    Achievement.where('number = 1').for_likes.all.each { |a|
      self.add_achievement(a)
    }
  end

  def give_init_real_achievements
    Achievement.where('number = 1').for_reals.all.each { |a|
      self.add_achievement(a)
    }
  end

  def give_init_comments_friends_achievements
    Achievement.where('number = 1').where(:kind => [Achievement::KIND::COMMENTS, Achievement::KIND::ADD_FRIENDS]).all.each { |a|
      self.add_achievement(a)
    }
  end

  def count_payments_sum
    sum = SprypayPayment.where(:state => true).where(:user_id => self.id).sum(:amount)
    sum += OnpayPayment.where(:state => true).where(:user_id => self.id).sum(:amount)
    self.update_attribute(:payments_sum, sum)
  end

  def unban_cost
    UNBAN_COST[ban_reason] || 0
  end

  def increase_limit_counter(redis_key)
    key = limits_key
    $redis_pool.with do |redis|
      res = redis.hget(key, redis_key)
      create_limits(key, redis) if res.blank?
      redis.hincrby(key, redis_key, 1)
    end
  end

  protected

  def give_money_to_referral
    if self.referral_id
      if !self.registration_provider.blank? && !self.registration_ip.blank?
        counter = Redis::Counter.new(User.reg_ip_key(self.registration_provider, self.registration_ip), expiration: 1.day)
        give_money_to_referral_impl if counter.value && counter.value.to_i <= 1
      else
        give_money_to_referral_impl
      end
    end
  end

  def give_money_to_referral_impl
    if referral.verified? && referral.premium?
      referral.add_referral_likes(User::REFERRAL_MONEY)
      referral.referrals_count += 1
      referral.save

      referral.process_achievement(Achievement::KIND::INVITE_REFERRAL)
    end
  end

  def today_limit_impl(redis_key)
    key = limits_key
    $redis_pool.with do |redis|
      res = redis.hget(key, redis_key)
      if res.blank?
        create_limits(key, redis)
        res = 0
      end
      res.to_i
    end
  end

  def create_limits(key = nil, redis)
    key ||= limits_key
    redis ||= Redis.current
    redis.multi do
      redis.hmset(key, :likes, 0, :groups, 0, :polls, 0, :comments, 0, :friends, 0)
      #Redis.current.expire(key, 5 * 60) # 5 minutes
      #Redis.current.expire(key, 60 * 60 * 12) # 12 hours
      redis.expire(key, 60 * 60 * 24) # 60 seconds * 60 minutes * 24 hours = 1 day
    end
  end

  def get_vizit_money_amount
    is_premium? ? PREMIUM_CONFIG[premium_type]['visit_money'].to_i : VIZIT_MONEY
  end

  def get_vizit_reals_amount
    return PREMIUM_CONFIG[premium_type]['visit_reals'].to_i if is_premium?
    return verified? ? VIZIT_REALS : 0
  end

  def limits_key
    "users-#{self.id}"
  end

  def set_auto_timestamps
    auto_poll_at = auto_like_at = auto_friend_at = auto_group_at = Time.now
  end

  def ban_cheaters
    if self.money < -30000
      self.ban_reason = BAN_REASON::CHEATER
    end
  end

  def set_initial_money
    self.money = INITIAL_MONEY
  end

  def strip_bad_name_symbols
    self.name = self.name.codepoints.select {|c| c < 50000}.pack("U*")
  end
end