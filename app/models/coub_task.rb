class CoubTask < ActiveRecord::Base
 belongs_to :user
 before_validation :set_max_count, on: :create
 after_validation  :set_max_count, on: :update

 after_validation  :set_shortcode, on: :create
 after_validation  :set_shortcode, on: :update

 def set_max_count
  self.max_count = self.cost.to_i * self.members_count.to_i
  self.current_count = self.max_count
 end

 def set_shortcode
  self.shortcode = CoubUrlParser.new(self.url).get_shortcode
 end

 validates :title, presence: true, length: { maximum: 255 }
 validates :members_count,  presence: true, numericality: { greater_than_or_equal_to: 10 }
 validates :cost,  presence: true, numericality: { greater_than_or_equal_to: 1,  less_than_or_equal_to: 15}
 URL_FORMAT = /https?:\/\/coub.com\/view\/(\w+)/i
 validates_format_of :url, :with => URL_FORMAT
end
