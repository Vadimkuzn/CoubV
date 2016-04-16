class CoubTask < ActiveRecord::Base
 belongs_to :user
 validates :title, presence: true, length: { maximum: 255 }
 validates :members_count,  presence: true, numericality: { greater_than_or_equal_to: 10 }
 validates :cost,  presence: true, numericality: { greater_than_or_equal_to: 1,  less_than_or_equal_to: 15}
 URL_FORMAT = /https?:\/\/coub.com\/view\/(\w+)/i
 validates_format_of :url, :with => URL_FORMAT
end
