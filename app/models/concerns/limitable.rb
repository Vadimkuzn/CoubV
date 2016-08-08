module Limitable
  extend ActiveSupport::Concern

  included do
    attr_accessor :current_limit_1_minute, :current_limit_5_minutes, :current_limit_15_minutes, :current_limit_1_hour, :current_limit_4_hours, :current_limit_1_day, :current_locked_for_bots
    belongs_to :task_limit

    alias :today_limit_exceeded? :limit_exceeded?
  end

  LIMIT_1_MINUTE = 60
  LIMIT_5_MINUTES = LIMIT_1_MINUTE * 5
  LIMIT_15_MINUTES = LIMIT_1_MINUTE * 15
  LIMIT_1_HOUR = LIMIT_1_MINUTE * 60
  LIMIT_4_HOURS = LIMIT_1_HOUR * 4
  LIMIT_1_DAY = LIMIT_1_HOUR * 24

  LIMIT_KEYS = [LIMIT_1_MINUTE, LIMIT_5_MINUTES, LIMIT_15_MINUTES, LIMIT_1_HOUR, LIMIT_4_HOURS, LIMIT_1_DAY]


  def limit_exceeded?
    if !self.task_limit_id.nil? && !self.task_limit.nil? && !self.task_limit.empty?
      actual_limits_now = $redis_pool.with do |redis|
        redis.mget(limits_key(60), limits_key(60 * 5), limits_key(60 * 15), limits_key(60 * 60), limits_key(4 * 60 * 60), limits_key(24 * 60 * 60))
      end

      return true if (actual_limits_now[0] || 0).to_i >= self.minute_1_limit
      return true if (actual_limits_now[1] || 0).to_i >= self.minutes_5_limit
      return true if (actual_limits_now[2] || 0).to_i >= self.minutes_15_limit
      return true if (actual_limits_now[3] || 0).to_i >= self.hour_1_limit
      return true if (actual_limits_now[4] || 0).to_i >= self.hours_4_limit
      return true if (actual_limits_now[5] || 0).to_i >= self.day_1_limit
    end

    false
  end

  def limit_for(expire)
    $redis_pool.with do |redis|
      (redis.get(limits_key(expire)) || 0).to_i
    end
  end

  def current_limit_values(keys = nil)
    keys ||= LIMIT_KEYS
    string_keys = keys.collect {|k| limits_key(k) }
    $redis_pool.with do |redis|
      redis.mget(string_keys).collect(&:to_i)
    end
  end

  def current_limits
    keys = LIMIT_KEYS
    limits = current_limit_values(keys)
    result = {}
    keys.each_with_index {|k, i| result[k] = limits[i] }
    result
  end
  
  def increase_limit_counter(c = 1)
    limits = LIMIT_KEYS
    if limits
      $redis_pool.with do |redis|
        limits.each {| k|
          current = redis.incrby(limits_key(k), c)
          redis.expire(limits_key(k), k) if current.to_i == c
        }
      end
    end
  end

  def decrease_limit_counter(c = 1)
    limits = LIMIT_KEYS
    if limits
      $redis_pool.with do |redis|
        limits.each {| k|
          current = redis.decrby(limits_key(k), c)
        }
      end
    end
  end

  def set_task_limit(params)
    if self.task_limit_id.blank?
      self.create_task_limit(params)
    else
      self.task_limit.update_attributes(params)
    end
  end

  def reset_limits!
    limits = LIMIT_KEYS
    $redis_pool.with do |redis|
      limits.each { |k|
        redis.expire(limits_key(k), 5)
      }
    end
  end

  def reset_limit!(period)
    $redis_pool.with do |redis|
      redis.expire(limits_key(period), 5)
    end
  end

  def create_limit(key, expire)
    key ||= limits_key(expire)
    $redis_pool.with do |redis|
      redis.setex(key, expire, 0)
    end
  end

  def give_to_bot?
    return !current_locked_for_bots if self.task_limit_id.nil?
    return false if current_locked_for_bots

#    return !locked_for_bots? if self.task_limit_id.nil?
#    return false if locked_for_bots?

    return false if current_limit_1_minute >= self.minute_1_limit
    return false if current_limit_5_minutes >= self.minutes_5_limit
    return false if current_limit_15_minutes >= self.minutes_15_limit
    return false if current_limit_1_hour >= self.hour_1_limit
    return false if current_limit_4_hours >= self.hours_4_limit
    return false if current_limit_1_day >= self.day_1_limit 

    true
  end

  def minute_1_limit
    #self.task_limit_id && self.task_limit.minute_1 ? [self.task_limit.minute_1, TaskLimit.default.minute_1].min : TaskLimit.default.minute_1
    self.task_limit_id && self.task_limit.minute_1 ? self.task_limit.minute_1 : TaskLimit.default.minute_1
  end

  def minutes_5_limit
    self.task_limit_id && self.task_limit.minutes_5 ? self.task_limit.minutes_5 : TaskLimit.default.minutes_5
  end

  def minutes_15_limit
    self.task_limit_id && self.task_limit.minutes_15 ? self.task_limit.minutes_15 : TaskLimit.default.minutes_15
  end

  def hour_1_limit
    #self.task_limit_id && self.task_limit.hour_1 ? [self.task_limit.hour_1, TaskLimit.default.hour_1].min : TaskLimit.default.hour_1
    self.task_limit_id && self.task_limit.hour_1 ? self.task_limit.hour_1 : TaskLimit.default.hour_1
  end

  def hours_4_limit
    self.task_limit_id && self.task_limit.hours_4 ? self.task_limit.hours_4 : TaskLimit.default.hours_4
  end

  def day_1_limit
    self.task_limit_id && self.task_limit.day_1 ? self.task_limit.day_1 : TaskLimit.default.day_1
  end

  def strict_minute_1_limit(max_value)
    self.task_limit_id && self.task_limit.minute_1 ? [self.task_limit.minute_1, max_value].min : max_value
  end

  def strict_minutes_5_limit(max_value)
    self.task_limit_id && self.task_limit.minutes_5 ? [self.task_limit.minutes_5, max_value].min : max_value
  end

  def strict_minutes_15_limit(max_value)
    self.task_limit_id && self.task_limit.minutes_15 ? [self.task_limit.minutes_15, max_value].min : max_value
  end

  def strict_hour_1_limit(max_value)
    self.task_limit_id && self.task_limit.hour_1 ? [self.task_limit.hour_1, max_value].min : max_value
  end

  def strict_hours_4_limit(max_value)
    self.task_limit_id && self.task_limit.hours_4 ? [self.task_limit.hours_4, max_value].min : max_value
  end

  def strict_day_1_limit(max_value)
    self.task_limit_id && self.task_limit.day_1 ? [self.task_limit.day_1, max_value].min : max_value
  end

  def stuck?
    stuck_for?(60, 50) || stuck_for?(60 * 5, 150) || stuck_for?(60 * 60, 500) || stuck_for?(4 * 60 * 60, 2000) || stuck_for?(24 * 60 * 60, 5000)
  end

  def stuck_for?(expire, limit)
    (Redis.current.exists(limits_key(expire)) && Redis.current.ttl(limits_key(expire)) == -1) # limit_for(expire) >= limit
  end

  def reject_task_limit(attributes)
    self.task_limit_id.nil? &&
    attributes[:minute_1].blank? &&
    attributes[:minutes_5].blank? &&
    attributes[:minutes_15].blank? &&
    attributes[:hour_1].blank? &&
    attributes[:hours_4].blank? &&
    attributes[:day_1].blank?
  end

end
