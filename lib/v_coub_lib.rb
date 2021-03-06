require 'uri'
require 'rest-client'
#=======================================================================
class VCoubLib
#-----------------------------------------------------------------------
AVATAR_SIZE = "medium_2x"
#-----------------------------------------------------------------------
 def initialize(user)
  raise ArgumentError if user.nil?
  @user = user
  @uapi = CoubApi::Client.new(user.auth_token)
 end
#-----------------------------------------------------------------------
 def channel_id_by_shortcode(shortcode)
  @uapi.get("channels/#{shortcode}")["id"]
 end
#-----------------------------------------------------------------------
 def channel_id_by_url(url)
  @uapi.get("channels/#{get_shortcode(url)}")["id"]
 end
#-----------------------------------------------------------------------
#  current_user.name
#  current_user.id
#  current_user.provider
#  current_user.uid
#  current_user.auth_token
#  current_user.created_at
#  current_user.updated_at

#-----------------------------------------------------------------------
 def get_current_user_api()
  CoubApi::Client.new(@user.auth_token)
 end
#-----------------------------------------------------------------------
 def get_shortcode(url)
  (url.split("/")[-1]).to_s
 end
#-----------------------------------------------------------------------
 def get_coub(url)
  @uapi.get("coubs/#{get_shortcode(url)}")
 end
#-----------------------------------------------------------------------
 def get_coub_id(url)
  get_coub(url)['id']
 end
#-----------------------------------------------------------------------
 def has_like?(coub_id)
   cuid = get_current_user_channel_id()
   likerslist = get_likers_list_by_id(coub_id)
   likerslist.each do |elm|
    if elm[2] == cuid
     return true
    end
   end
   false
 end
#-----------------------------------------------------------------------
 def has_like_url?(url)
   cuid = get_current_user_channel_id()
   likerslist = get_likers_list(url)
   likerslist.each do |elm|
    if elm[2] == cuid
     return true
    end
   end
   false
 end
#-----------------------------------------------------------------------

# ar:
# — page (integer) — the number of the required page;
# — total_pages (integer) — the number of all pages;

# — channels (array) — the array of channel small JSONs:

# — id (integer) — the identifier of the channel;
# — permalink (string) — the permalink of the channel;
# — description (string) — the description of the channel;
# — title (string) — the title of the channel;
# — i_follow_him (boolean) — whether this channel is followed by you;
# — followers_count (integer) — the number of channel's followers;
# — following_count (integer) — the number of channels that the channel follows;
# — avatar_versions (JSON) — the JSON object that contains data about channel's thumbnail images:
# — template (string) — the template of the URLs to the files specified in this JSON;
# — versions (array) — the array of strings that refer to available image versions: — medium — 48x48 pixels;
# — medium_2x — 96x96 pixels;
# — profile_pic — 160x160 pixels;
# — profile_pic_2x — 320x320 pixels;
# — profile_pic_new — 110x110 pixels;
# — profile_pic_new_2x — 220x220 pixels;
# — tiny — 32x32 pixels;
# — tiny_2x — 64x64 pixels;
# — small — 38x38 pixels;
# — small_2x — 76x76 pixels;
# — ios_large — 140x140 pixels;
# — ios_small — 70x70 pixels.

#-----------------------------------------------------------------------
 def get_likers_list(url)
  get_likers_list_by_id(get_coub_id(url))
 end
#-----------------------------------------------------------------------
 def get_likers_list_by_id(coub_id)
  begin
   ar  = @uapi.get('action_subjects_data/coub_likes_list', id: coub_id, page: 1)
   rescue
    nil
    return
  end
  arch = ar['channels']
  churls = []
  arch.each do |ch|
   churl = []
   churl  << ch["title"]
   churl  << "http://coub.com/#{ch['permalink']}"
   churl  << ch["id"]
   churls << churl
  end
  churls
 end

# ar:
# — page (integer) — the number of the required page;
# — total_pages (integer) — the number of all pages;

# — channels (array) — the array of channel small JSONs:

# — id (integer) — the identifier of the channel;
# — permalink (string) — the permalink of the channel;
# — description (string) — the description of the channel;
# — title (string) — the title of the channel;
# — i_follow_him (boolean) — whether this channel is followed by you;
# — followers_count (integer) — the number of channel's followers;
# — following_count (integer) — the number of channels that the channel follows;
# — avatar_versions (JSON) — the JSON object that contains data about channel's thumbnail images:
# — template (string) — the template of the URLs to the files specified in this JSON;
# — versions (array) — the array of strings that refer to available image versions: — medium — 48x48 pixels;
# — medium_2x — 96x96 pixels;
# — profile_pic — 160x160 pixels;
# — profile_pic_2x — 320x320 pixels;
# — profile_pic_new — 110x110 pixels;
# — profile_pic_new_2x — 220x220 pixels;
# — tiny — 32x32 pixels;
# — tiny_2x — 64x64 pixels;
# — small — 38x38 pixels;
# — small_2x — 76x76 pixels;
# — ios_large — 140x140 pixels;
# — ios_small — 70x70 pixels.

#-----------------------------------------------------------------------
 def get_following_list(channel_id)
  begin
   ar  = @uapi.get('action_subjects_data/followings_list', id: channel_id, page: 1)
  rescue
   nil
   return
  end
  ar['channels'].collect { |ch| ch['id'] }
 end
#-----------------------------------------------------------------------
 def get_followers_list(channel_id)
  begin
   ar  = @uapi.get('action_subjects_data/followers_list', id: channel_id, page: 1)
  rescue
   nil
   return
  end
  ar['channels'].collect { |ch| ch['id'] }
 end
#-----------------------------------------------------------------------
 def get_current_user_info()
  @uapi.get('users/me')
 end
# — id (integer) — the identifier of the user;
# — permalink (string) — the permalink of the user;
# — name (string) — the name of the user;
# — sex (string) — the gender of the user, can be set to one of the following values: male, female, unspecified.
# — city (string) — the city that the user specified in the profile;
# — current_channel (JSON) — the channel small JSON relates to the channel that currently chosen by the user;
# — created_at (UNIX-time) — the time when the user profile was created;
# — updated_at (UNIX-time) — the time of the user profile's last update;
# — api_token (string) — the current access token.
#-----------------------------------------------------------------------
 def get_current_user_channel()
  get_current_user_info()["current_channel"]
 end
#-----------------------------------------------------------------------
 def get_current_user_channel_id()
  get_current_user_channel()["id"]
 end
#-----------------------------------------------------------------------
 def get_current_user_id()
  get_current_user_info()["id"]
 end
#-----------------------------------------------------------------------
 def get_current_user_avatar()
  avatar_url = get_current_user_channel()["avatar_versions"]["template"]
  avatar_url.gsub!(/%{version}/, AVATAR_SIZE)
 end
#-----------------------------------------------------------------------
 def general_search(str)
  @uapi.get('search', q: str)
 end
#-----------------------------------------------------------------------
 def get_avatar(url)
  avatar_url = @uapi.get("channels/#{channel_id_by_url(url).to_i}")["avatar_versions"]["template"]
  avatar_url.gsub!(/%{version}/, AVATAR_SIZE)
 end
#-----------------------------------------------------------------------
 def does_follow?(channel_id)
  get_followers_list(channel_id).include? get_current_user_channel_id()
 end
#-----------------------------------------------------------------------
 def has_follow_url?(url)
  get_following_list(get_current_user_channel_id()).include? channel_id_by_url(url)
 end
#-----------------------------------------------------------------------
 def valid?(url)
  URI.parse(url).kind_of?(URI::HTTP)
 rescue URI::InvalidURIError
  false
 end
#-----------------------------------------------------------------------
 def get_url_source(url)
  response = RestClient.get(url)
# response.body
 end
#-----------------------------------------------------------------------
 def get_channel_id_by_url(url)
  hasharr = get_JSON_hasharr_by_url(url)
  hasharr.each do |shash|
   lresult = shash["channel_id"]
   if lresult
    return lresult.to_i
   end
  end
  nil
 end
#-----------------------------------------------------------------------
 def get_JSON_hasharr_by_url(url)
  hasharr = []
  result = RestClient.get(url).body.scan(/<script type='text\/json'>.*?(\{.*?)<\/script>/m)
  result.each {|elm| hasharr << JSON.parse(elm[0].strip)}
  hasharr
 end
#-----------------------------------------------------------------------
 def task_completed?(task)
  completed = false
  if task.type == "CoubLikeTask"
   completed = has_like_url?(task[:url])
  else
   completed = has_follow_url?(task[:url])
  end
  completed
 end
#-----------------------------------------------------------------------
end

#=======================================================================

class String
 def save_file(filename)
  open(filename, 'wb') do |f|
   f << "#{self}"
  end
 end
#-----------------------------------------------------------------------
 def append_file(filename)
  open(filename, 'ab') do |f|
   f << "#{self}"
  end
 end
#-----------------------------------------------------------------------
end
#-----------------------------------------------------------------------
