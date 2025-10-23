# frozen_string_literal: true

module Doing
  # Handling of @tags in strings
  module StringTags
    ##
    ## Add @ prefix to string if needed, maintains +/- prefix
    ##
    ## @return     [String] @string
    ##
    def add_at
      strip.sub(/^([+-]*)@?/, '\1@')
    end

    ##
    ## Removes @ prefix if needed, maintains +/- prefix
    ##
    ## @return     [String] string without @ prefix
    ##
    def remove_at
      strip.sub(/^([+-]*)@?/, '\1')
    end

    ##
    ## Split a string of tags, remove @ symbols, with or
    ## without @ symbols, with or without parenthetical
    ## values
    ##
    ## @return     [Array] array of tags without @ symbols
    ##
    def split_tags
      gsub(/ *, */, ' ').scan(/(@?(?:\S+(?:\(.+\)))|@?(?:\S+))/).map(&:first).map(&:remove_at).sort.uniq
    end

    ##
    ## Convert a list of tags to an array. Tags can be with
    ## or without @ symbols, separated by any character, and
    ## can include parenthetical values (with spaces)
    ##
    ## @return     [Array] array of tags including @ symbols
    ##
    def to_tags
      arr = split_tags.map(&:add_at)
      if block_given?
        yield arr
      else
        arr
      end
    end

    ##
    ## Adds tags to a string
    ##
    ## @param      tags    [String or Array] List of tags to add. @ symbol optional
    ## @param      remove  [Boolean] remove tags instead of adding
    ##
    ## @return     [String] the tagged string
    ##
    def add_tags(tags, remove: false)
      title = dup
      tags = tags.to_tags
      tags.each { |tag| title.tag!(tag, remove: remove) }
      title
    end

    ## @see #add_tags
    def add_tags!(tags, remove: false)
      replace add_tags(tags, remove: remove)
    end

    ##
    ## Add, rename, or remove a tag in place
    ##
    ## @see #tag
    ##
    def tag!(tag, **options)
      replace tag(tag, **options)
    end

    ##
    ## Add, rename, or remove a tag
    ##
    ## @param      tag        The tag
    ## @param      value      [String] Value for tag (@tag(value))
    ## @param      remove     [Boolean] Remove the tag instead of adding
    ## @param      rename_to  [String] Replace tag with this tag
    ## @param      regex      [Boolean] Tag is regular expression
    ## @param      single     [Boolean] Operating on a single item (for logging)
    ## @param      force      [Boolean] With rename_to, add tag if it doesn't exist
    ##
    ## @return     [String] The string with modified tags
    ##
    def tag(tag, value: nil, remove: false, rename_to: nil, regex: false, single: false, force: false)
      log_level = single ? :info : :debug
      title = dup
      title.chomp!
      tag = tag.sub(/^@?/, '')
      case_sensitive = tag !~ /[A-Z]/

      rx_tag = if regex
                 tag.gsub(/\./, '\S')
               else
                 tag.gsub(/\?/, '.').gsub(/\*/, '\S*?')
               end

      if remove || rename_to
        rx = Regexp.new("(?<=^| )@#{rx_tag}(?<parens>\\((?<value>[^)]*)\\))?(?= |$)", case_sensitive)
        m = title.match(rx)

        if m.nil? && rename_to && force
          title.tag!(rename_to, value: value, single: single)
        elsif m
          title.gsub!(rx) do
            if rename_to
              "@#{rename_to}#{value.nil? ? m['parens'] : "(#{value})"}"
            else
              ''
            end
          end

          title.dedup_tags!
          title.chomp!

          f = "@#{tag}".cyan
          if rename_to
            t = "@#{rename_to}".cyan
            Doing.logger.write(log_level, 'Tag:', %(renamed #{f} to #{t} in "#{title}"))
          else
            Doing.logger.write(log_level, 'Tag:', %(removed #{f} from "#{title}"))
          end
        else
          Doing.logger.debug('Skipped:', "not tagged #{"@#{tag}".cyan}")
        end
      elsif title =~ /@#{tag}(?=[ (]|$)/ && !value.good?
        Doing.logger.debug('Skipped:', "already tagged #{"@#{tag}".cyan}")
        return title
      else
        add = tag
        add += "(#{value})" unless value.nil?

        title.chomp!

        if value && title =~ /@#{tag}(?=[ (]|$)/
          title.sub!(/@#{tag}(\(.*?\))?/, "@#{add}")
        else
          title += " @#{add}"
        end

        title.dedup_tags!
        title.chomp!
        Doing.logger.write(log_level, 'Tag:', %(added #{"@#{tag}".cyan} to "#{title}"))
      end

      title.gsub(/ +/, ' ')
    end

    ##
    ## Remove duplicate tags, leaving only first occurrence
    ##
    ## @return     Deduplicated string
    ##
    def dedup_tags
      title = dup
      tags = title.scan(/(?<=\A| )(@(\S+?)(\([^)]+\))?)(?= |\Z)/).uniq
      tags.each do |tag|
        found = false
        title.gsub!(/( |^)#{Regexp.escape(tag[1])}(\([^)]+\))?(?= |$)/) do |m|
          if found
            ''
          else
            found = true
            m
          end
        end
      end
      title
    end

    ## @see #dedup_tags
    def dedup_tags!
      replace dedup_tags
    end
  end
end
