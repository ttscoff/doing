# frozen_string_literal: true

module Doing
  ##
  ## String to symbol conversion
  ##
  module StringNormalize
    ##
    ## Convert tag sort string to a qualified type
    ##
    ## @return     [Symbol] :name or :time
    ##
    def normalize_tag_sort(default = :name)
      case self
      when /^n/i
        :name
      when /^t/i
        :time
      else
        default
      end
    end

    ## @see #normalize_tag_sort
    def normalize_tag_sort!(default = :name)
      replace normalize_tag_sort(default)
    end

    ##
    ## Normalize list output style
    ##
    ## @param      default  The default
    ##
    ## @return [Symbol] :comma, :column, :tab, :space
    ##
    def normalize_list_style(default = :space)
      case self
      when /^com/i
        :comma
      when /^c/i
        :column
      when /^t/i
        :tab
      else
        :space
      end
    end

    ##
    ## Convert an age string to a qualified type
    ##
    ## @return     [Symbol] :oldest or :newest
    ##
    def normalize_age(default = :newest)
      case self
      when /^o/i
        :oldest
      when /^n/i
        :newest
      else
        default
      end
    end

    ## @see #normalize_age
    def normalize_age!(default = :newest)
      replace normalize_age(default)
    end

    ##
    ## Convert a sort order string to a qualified type
    ##
    ## @return     [Symbol] :asc or :desc
    ##
    def normalize_order!(default = :asc)
      replace normalize_order(default)
    end

    def normalize_order(default = :asc)
      case self
      when /^a/i
        :asc
      when /^d/i
        :desc
      else
        default
      end
    end

    ##
    ## Convert a case sensitivity string to a symbol
    ##
    ## @return     Symbol :smart, :sensitive, :ignore
    ##
    def normalize_case(default = :smart)
      case self
      when /^(c|sens)/i
        :sensitive
      when /^i/i
        :ignore
      when /^s/i
        :smart
      else
        default.is_a?(Symbol) ? default : default.normalize_case
      end
    end

    ## @see #normalize_case
    def normalize_case!(default = :smart)
      replace normalize_case(default)
    end

    ##
    ## Convert a boolean string to a symbol
    ##
    ## @return     Symbol :and, :or, or :not
    ##
    def normalize_bool(default = :and)
      case self
      when /(and|all)/i
        :and
      when /(any|or)/i
        :or
      when /(not|none)/i
        :not
      when /^p/i
        :pattern
      else
        default.is_a?(Symbol) ? default : default.normalize_bool
      end
    end

    ## @see #normalize_bool
    def normalize_bool!(default = :and)
      replace normalize_bool(default)
    end

    ##
    ## Convert a matching configuration string to a symbol
    ##
    ## @param      default  [Symbol] the default matching
    ##                      type to return if the string
    ##                      doesn't match a known symbol
    ## @return     Symbol :fuzzy, :pattern, :exact
    ##
    def normalize_matching(default = :pattern)
      case self
      when /^f/i
        :fuzzy
      when /^p/i
        :pattern
      when /^e/i
        :exact
      else
        default.is_a?(Symbol) ? default : default.normalize_matching
      end
    end

    ## @see #normalize_matching
    def normalize_matching!(default = :pattern)
      replace normalize_bool(default)
    end

    ##
    ## Adds ?: to any parentheticals in a regular expression
    ## to avoid match groups
    ##
    ## @return     [String] modified regular expression
    ##
    def normalize_trigger
      gsub(/\((?!\?:)/, '(?:').downcase
    end

    ## @see #normalize_trigger
    def normalize_trigger!
      replace normalize_trigger
    end

    def normalize_change_type
      case self
      when /^c/i
        :changed
      when /^i/i
        :improved
      when /^f/i
        :fixed
      when /^n/i
        :new
      end
    end
  end

  ##
  ## Symbol helpers
  ##
  module SymbolNormalize
    def normalize_tag_sort(default = :name)
      to_s.normalize_tag_sort
    end

    def normalize_bool(default = :and)
      to_s.normalize_bool(default)
    end

    def normalize_age(default = :newest)
      to_s.normalize_age(default)
    end

    def normalize_order(default = :asc)
      to_s.normalize_order(default)
    end

    def normalize_case(default = :smart)
      to_s.normalize_case(default)
    end

    def normalize_matching(default = :pattern)
      to_s.normalize_matching(default)
    end
  end
end

class ::String
  include Doing::StringNormalize
end

class ::Symbol
  include Doing::SymbolNormalize
end
