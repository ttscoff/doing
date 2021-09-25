##
## @brief      Hash helpers
##
class ::Hash
  def has_tags?(tags, bool = :and)
    tags = tags.split(/ *, */) if tags.is_a? String
    bool = bool.normalize_bool if bool.is_a? String
    item = self
    tags.map! {|t| t.strip.sub(/^@/, '')}
    case bool
    when :and
      result = true
      tags.each do |tag|
        unless item['title'] =~ /@#{tag}/
          result = false
          break
        end
      end
      result
    when :not
      result = true
      tags.each do |tag|
        if item['title'] =~ /@#{tag}/
          result = false
          break
        end
      end
      result
    else
      result = false
      tags.each do |tag|
        if item['title'] =~ /@#{tag}/
          result = true
          break
        end
      end
      result
    end
  end

  def matches_search?(search)
    item = self
    text = item['note'] ? item['title'] + item['note'].join(' ') : item['title']
    pattern = if search.strip =~ %r{^/.*?/$}
                search.sub(%r{/(.*?)/}, '\1')
              else
                search.split('').join('.{0,3}')
              end
    text =~ /#{pattern}/i ? true : false
  end
end

##
## @brief      String helpers
##
class ::String
  def cap_first
    sub(/^\w/) do |m|
      m.upcase
    end
  end


  ##
  ## @brief      Convert a boolean string to a symbol
  ##
  ## @return     Symbol :and, :or, or :not
  ##
  def normalize_bool!
    replace normalize_bool
  end

  def normalize_bool(default = :and)
    case self
    when /(and|all)/i
      :and
    when /(any|or)/i
      :or
    when /(not|none)/i
      :not
    else
      default.is_a?(Symbol) ? default : default.normalize_bool
    end
  end


  ##
  ## @brief      Turn raw urls into HTML links
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def link_urls(opt = {})
    opt[:format] ||= :html
    if opt[:format] == :html
      gsub(%r{(?mi)((http|https)://)([\w\-_]+(\.[\w\-_]+)+)([\w\-.,@?^=%&amp;:/~+#]*[\w\-@^=%&amp;/~+#])?}) do |_match|
        m = Regexp.last_match
        proto = m[1].nil? ? 'http://' : ''
        %(<a href="#{proto}#{m[0]}" title="Link to #{m[0]}">[#{m[3]}]</a>)
      end.gsub(/<(\w+:.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /<a href/
          match
        else
          %(<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>)
        end
      end
    else
      self
    end
  end
end

class ::Symbol
  def normalize_bool!
    replace normalize_bool
  end

  def normalize_bool
    to_s.normalize_bool
  end
end
