class CoubFollowTask < CoubTask
 include Pausable
 include Destroyable
 include Lockable
 include Limitable
 include CommonTask

 TASK_LOCK_TIME = 25

 URL_FORMAT = /https?:\/\/coub.com\/([\w\.]+)/i
 validates_format_of :url, :with => URL_FORMAT

 before_validation :set_shortcode

 def set_shortcode
  self.shortcode = CoubUrlParser.get_shortcode(self.url)
  self.item_id = VCoubLib.new(user).channel_id_by_shortcode(shortcode)
#  shortcode.append_file('c:\fshortcode.txt')
 end
end
