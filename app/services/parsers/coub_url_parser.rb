class CoubUrlParser < String
 def get_shortcode()
  arr = self.scan(/\w+/)
  arr[-1]
 end
end
