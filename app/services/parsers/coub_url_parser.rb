class CoubUrlParser
 def self.get_shortcode(url)
  url.split("/")[-1]
 end
end
