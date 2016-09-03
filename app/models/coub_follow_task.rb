class CoubFollowTask < CoubTask
 URL_FORMAT = /https?:\/\/coub.com\/([\w\.]+)/i
 validates_format_of :url, :with => URL_FORMAT

 before_validation :set_shortcode

 def set_shortcode
  self.shortcode = CoubUrlParser.new(self.url).get_shortcode
  self.item_id = VCoubLib.new(user).channel_id_by_shortcode(shortcode)
#shortcode.append_file('c:\fshortcode.txt')
 end
end
