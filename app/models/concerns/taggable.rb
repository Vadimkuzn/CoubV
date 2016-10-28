module Taggable
  extend ActiveSupport::Concern
  
  included do
    acts_as_taggable
  end

  def included_tag_list
    tags.collect(&:name)
  end

end