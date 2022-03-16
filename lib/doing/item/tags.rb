# frozen_string_literal: true

module Doing
  # A Doing entry
  module ItemTags
    ##
    ## Add (or remove) tags from the title of the item
    ##
    ## @param      tags    [Array] The tags to apply
    ## @param      options Additional options
    ##
    ## @option options :date       [Boolean] Include timestamp?
    ## @option options :single     [Boolean] Log as a single change?
    ## @option options :value      [String] A value to include as @tag(value)
    ## @option options :remove     [Boolean] if true remove instead of adding
    ## @option options :rename_to  [String] if not nil, rename target tag to this tag name
    ## @option options :regex      [Boolean] treat target tag string as regex pattern
    ## @option options :force      [Boolean] with rename_to, add tag if it doesn't exist
    ##
    def tag(tags, **options)
      added = []
      removed = []

      date = options.fetch(:date, false)
      options[:value] ||= date ? Time.now.strftime('%F %R') : nil
      options.delete(:date)

      single = options.fetch(:single, false)
      options.delete(:single)

      tags = tags.to_tags if tags.is_a? ::String

      remove = options.fetch(:remove, false)
      tags.each do |tag|
        if tag =~ /^(\S+)\((.*?)\)$/
          m = Regexp.last_match
          tag = m[1]
          options[:value] ||= m[2]
        end

        bool = remove ? :and : :not
        if tags?(tag, bool) || options[:value]
          @title = @title.tag(tag, **options).strip
          remove ? removed.push(tag) : added.push(tag)
        end
      end

      Doing.logger.log_change(tags_added: added, tags_removed: removed, count: 1, item: self, single: single)

      self
    end

    ##
    ## Get a list of tags on the item
    ##
    ## @return     [Array] array of tags (no values)
    ##
    def tags
      @title.scan(/(?<= |\A)@([^\s(]+)/).map { |tag| tag[0] }.sort.uniq
    end

    ##
    ## Return all tags including parenthetical values
    ##
    ## @return     [Array<Array>] Array of array pairs,
    ##             [[tag1, value], [tag2, value]]
    ##
    def tags_with_values
      @title.scan(/(?<= |\A)@([^\s(]+)(?:\((.*?)\))?/).map { |tag| [tag[0], tag[1]] }.sort.uniq
    end

    ##
    ## convert tags on item to an array with @ symbols removed
    ##
    ## @return     [Array] array of tags
    ##
    def tag_array
      tags.tags_to_array
    end

    private

    def split_tags(tags)
      tags.to_tags.tags_to_array
    end
  end
end
