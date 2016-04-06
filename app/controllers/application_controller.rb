class ApplicationController < ActionController::Base
 # Prevent CSRF attacks by raising an exception.
 # For APIs, you may want to use :null_session instead.

 String.class_eval do
  def is_valid_url?
   uri = URI.parse self
   uri.kind_of? URI::HTTP
    rescue URI::InvalidURIError
   false
  end
 end

 protect_from_forgery with: :exception
end
