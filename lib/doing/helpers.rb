##
## @brief      Date helpers
##
class ::Time
  def relative_date
    if self > Date.today.to_time
      strftime('    %_I:%M%P')
    elsif self > (Date.today - 6).to_time
      strftime('%a %_I:%M%P')
    elsif self.year == Date.today.year
      strftime('%m/%d %_I:%M%P')
    else
      strftime('%m/%d/%Y %_I:%M%P')
    end
  end
end

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
  ## @brief      Convert a sort order string to a qualified type
  ##
  ## @return     (String) 'asc' or 'desc'
  ##
  def normalize_order!
    replace normalize_order
  end

  def normalize_order(default = 'asc')
    case self
    when /^a/i
      'asc'
    when /^d/i
      'desc'
    else
      default
    end
  end

  ##
  ## @brief      Convert a boolean string to a symbol
  ##
  ## @return     Symbol :and, :or, or :not
  ##
  def normalize_bool!
    replace normalize_boolm
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
  ## @brief      Remove duplicate tags, leaving only first occurrence
  ##
  ## @return     Deduplicated string
  ##
  def dedup_tags!
    replace dedup_tags
  end

  def dedup_tags
    item = self.dup
    tags = item.scan(/(?<=^| )(\@(\S+?)(\([^)]+\))?)(?=\b|$)/).uniq
    tags.each do |tag|
      found = false
      item.gsub!(/( |^)#{tag[0]}\b/) do |m|
        if found
          ''
        else
          found = true
          m
        end
      end
    end
    item
  end

  ##
  ## @brief      Turn raw urls into HTML links
  ##
  ## @param      opt   (Hash) Additional Options
  ##
  def link_urls!(opt = {})
    replace link_urls(opt)
  end

  def link_urls(opt = {})
    opt[:format] ||= :html
    str = self.dup

    if :format == :markdown
      # Remove <self-linked> formatting
      str.gsub!(/<(.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /^https?:/
          m[1]
        else
          match
        end
      end
    end

    # Replace qualified urls
    str.gsub!(%r{(?mi)(?<!["'\[(\\])((http|https)://)([\w\-_]+(\.[\w\-_]+)+)([\w\-.,@?^=%&amp;:/~+#]*[\w\-@^=%&amp;/~+#])?}) do |_match|
      m = Regexp.last_match
      proto = m[1].nil? ? 'http://' : ''
      case opt[:format]
      when :html
        %(<a href="#{proto}#{m[0]}" title="Link to #{m[0]}">[#{m[3]}]</a>)
      when :markdown
        "[#{m[0]}](#{proto}#{m[0]})"
      else
        m[0]
      end
    end

    # Clean up unlinked <urls>
    str.gsub!(/<(\w+:.*?)>/) do |match|
      m = Regexp.last_match
      if m[1] =~ /<a href/
        match
      else
        %(<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>)
      end
    end

    str
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
