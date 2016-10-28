module Lockable
  extend ActiveSupport::Concern
  
  VERY_LONG_LOCK = 15.minutes
  LONG_LOCK = 9.minutes
  NORMAL_LOCK = 4.minutes
  SHORT_LOCK = 60.seconds


  def lock_key
    "#{self.class.name}-lock-#{self.id}"
  end

  def lock_for_bots!(by = nil, redis = nil)
#    unless self.id == 773833
#      puts "in Logaza condition"
#      lock_seconds = rand(lock_time) + 7
#    else
      if need_random_locks?
        if possibility(5)
          lock_seconds = rand(5..VERY_LONG_LOCK.seconds.to_i) + 1
        elsif possibility(10)
          lock_seconds = rand(5..LONG_LOCK.seconds.to_i) + 1
        elsif possibility(30)
          lock_seconds = rand(5..NORMAL_LOCK.seconds.to_i) + 1
        elsif possibility(50)
          lock_seconds = rand(5..SHORT_LOCK.seconds.to_i) + 1
        else
          lock_seconds = rand(lock_time) + 1
        end
      else
        lock_seconds = rand(lock_time) + 1
      end
#    end
    #begin
      if redis
        return lock_for_bots_impl(redis, lock_seconds, by.nil? ? '1' : by.id.to_s)
      else
        $redis_pool.with do |redis|
          return lock_for_bots_impl(redis, lock_seconds, by.nil? ? '1' : by.id.to_s)
        end
      end
    # rescue => ex
    #   Rails.logger.error("Could not lock task for: #{lock_seconds}, exception: #{ex.inspect}")
    # end
    false
  end

  def lock_for_bots_impl(redis, lock_seconds, by)
    key = lock_key
    result = redis.multi do
      redis.setnx(key, by)
      redis.expire(key, lock_seconds)
    end
    result.first
  end

  def locked_for_bots?
    $redis_pool.with do |redis|
      redis.exists(lock_key)
    end
  end

  def lock_for_bots_time
    $redis_pool.with do |redis|
      redis.ttl(lock_key)
    end
  end

  def unlock_for_bots!
    $redis_pool.with do |redis|
      redis.del(lock_key)
    end
  end

  def possibility(percent_half)
    rand(1000) < percent_half
  end

end