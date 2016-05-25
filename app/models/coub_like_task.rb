class CoubLikeTask < CoubTask
  URL_FORMAT = /https?:\/\/coub.com\/view\/(\w+)/i
  validates_format_of :url, :with => URL_FORMAT

  before_validation :set_shortcode

  def set_shortcode
    self.shortcode = CoubUrlParser.new(self.url).get_shortcode
    self.item_id = VCoubLib.new(user).get_coub_id(url)
  end
end
