module Authentication
  def self.included(recipient)
    recipient.extend(ModelClassMethods)
    recipient.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(social_name, social_id)
      first :conditions => ["#{social_name}_id = ?", social_id]
    end
    
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

  end # class methods

  module ModelInstanceMethods
    def encrypt(password)
      self.class.encrypt(password, 'fotgo is the best resource ever seen!')
    end
    
    
    def remember_token?
      remember_token_expires_at && Time.now.utc < remember_token_expires_at
    end

    # These create and unset the fields required for remembering users between browser closes
    def remember_me
      remember_me_for 3.month
    end

    def remember_me_for(time)
      remember_me_until time.from_now.utc
    end

    def remember_me_until(time)
      self.remember_token_expires_at = time
      self.remember_token            = encrypt("btuwe55evvere-#{id}-asdasdrterter345345")
      save
    end

    def forget_me
      self.remember_token_expires_at = nil
      self.remember_token            = nil
      save
    end

  end # instance methods
end
