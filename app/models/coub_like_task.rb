class CoubLikeTask < CoubTask
 include Pausable
 include Destroyable
 include Lockable
 include Limitable
 include CommonTask

 TASK_LOCK_TIME = 25

 URL_FORMAT = /https?:\/\/coub.com\/view\/([\w\.]+)/i
 validates_format_of :url, :with => URL_FORMAT

 before_validation :set_shortcode

 def set_shortcode
  self.shortcode = CoubUrlParser.get_shortcode(self.url)
  self.item_id = VCoubLib.new(user).get_coub_id(self.url)
#shortcode.append_file('c:\lshortcode.txt')
 end
end
