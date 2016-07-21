class ApplicationController < ActionController::Base
 # Prevent CSRF attacks by raising an exception.
 # For APIs, you may want to use :null_session instead.
 protect_from_forgery with: :exception

 helper_method :current_user
 def current_user
  @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
#<User id: 1, provider: "coub", uid: "3240053", auth_token: "808c4832a0ac66afda4077a6fd77f86d51202f5318ddd0ff04...", name: "vadimkuzn", created_at: "2016-04-20 19:02:37", updated_at: "2016-07-06 14:54:06">
 end

end
