# source: http://stackoverflow.com/questions/1293573/rails-smart-text-truncation
def smart_truncate(text, char_limit)
  size = 0
  text.split.reject do |token|
    size += (token.size + 1)
    size > char_limit
  end.join(" ") + (text.size >= char_limit ? " ..." : "" )
end
