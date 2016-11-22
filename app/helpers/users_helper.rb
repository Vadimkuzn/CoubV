module UsersHelper
  def ban_reason(u)
    case u.ban_reason
      when User::BAN_REASON::ADS then I18n.t('users.ban_reason.ads')
      when User::BAN_REASON::FORBIDDEN_GROUP then I18n.t('users.ban_reason.forbidden_group')
      when User::BAN_REASON::CHEATER then I18n.t('users.ban_reason.cheater')
      when User::BAN_REASON::CHEATER_FRIEND then I18n.t('users.ban_reason.cheater_friend')
      when User::BAN_REASON::CLOSED_GROUP then I18n.t('users.ban_reason.closed_group')
      when User::BAN_REASON::OFTEN_BANS then I18n.t('users.ban_reason.often_bans')
      when User::BAN_REASON::USE_BAD_BOTS then I18n.t('users.ban_reason.use_bad_bots')
    end
  end
  
  def from_transaction_to_string(t)
    I18n.t('users.money_transaction.from', :time => l(t.created_at.in_time_zone('Moscow'), :format => :short), :amount => t.amount_from, :name => t.to ? t.to.name : 'NoName')
  end
  
  def to_transaction_to_string(t)
    I18n.t('users.money_transaction.to', :time => l(t.created_at.in_time_zone('Moscow'), :format => :short), :amount => t.amount_to, :name => t.from ? t.from.name : 'NoName')
  end

  def premium_until_in_words(time)
    days = ((time - Time.now).to_i / 1.day)
    time - Time.now > 1.day ? "#{days} #{Russian::p(days, Russian.t('1_day'), Russian.t('2_days'), Russian.t('many_days'))}" : distance_of_time_in_words_to_now(time)
  end

  def user_receive_likes_limit(u)
    u.is_premium? ? "&infin;" : User::RECEIVE_LIKES_IN_MONTH
  end

end
