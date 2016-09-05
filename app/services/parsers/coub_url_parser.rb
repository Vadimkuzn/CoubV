class CoubUrlParser < String
 def get_shortcode()
  self.split("/")[-1]
 end
end
