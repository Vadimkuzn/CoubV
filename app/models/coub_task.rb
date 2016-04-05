class CoubTask < ActiveRecord::Base
 validates :title, presence: true, length: { maximum: 255 }
 validates :url,   presence: true, length: { maximum: 255 }
 validates :members_count,  presence: true, numericality: { greater_than_or_equal_to: 10 }
 validates :cost,  presence: true, numericality: { greater_than_or_equal_to: 1 }
end