# frozen_string_literal: true

module Doing
  ##
  ## @brief      This class describes a single WWID item
  ##
  class Item
    attr_accessor :date, :title, :section, :note

    def initialize(date, title, section, note = nil)
      @date = date.is_a?(Time) ? date : Time.parse(date)
      @title = title
      @section = section
      @note = Note.new(note)
    end

    # def date=(new_date)
    #   @date = new_date.is_a?(Time) ? new_date : Time.parse(new_date)
    # end

    def interval
      @interval ||= calc_interval
    end

    def end_date
      @end_date ||= Time.parse(Regexp.last_match(1)) if @title =~ /@done\((\d{4}-\d\d-\d\d \d\d:\d\d.*?)\)/
    end

    def equal?(other)
      return false if @title.strip != other.title.strip

      return false if @date != other.date

      return false unless @note.equal?(other.note)

      true
    end

    def same_time?(item_b)
      date == item_b.date ? interval == item_b.interval : false
    end

    def overlapping_time?(item_b)
      return true if same_time?(item_b)

      start_a = date
      interval = interval
      end_a = interval ? start_a + interval.to_i : start_a
      start_b = item_b.date
      interval = item_b.interval
      end_b = interval ? start_b + interval.to_i : start_b
      (start_a >= start_b && start_a <= end_b) || (end_a >= start_b && end_a <= end_b) || (start_a < start_b && end_a > end_b)
    end

    def tag(tag, value: nil, remove: false, rename_to: nil, regex: false)
      @title.tag!(tag, value: value, remove: remove, rename_to: rename_to, regex: regex).strip!
    end

    def tags
      @title.scan(/(?<= |\A)@([^\s(]+)/).map {|tag| tag[0]}.sort.uniq
    end

    def tags?(tags, bool = :and)
      tags = split_tags(tags)
      bool = bool.normalize_bool

      case bool
      when :and
        all_tags?(tags)
      when :not
        no_tags?(tags)
      else
        any_tags?(tags)
      end
    end

    def search(search)
      text = @title + @note.to_s
      pattern = case search.strip
                when %r{^/.*?/$}
                  search.sub(%r{/(.*?)/}, '\1')
                when /^'/
                  case_sensitive = true
                  search.sub(/^'(.*?)'?$/, '\1')
                else
                  case_sensitive = true if search =~ /[A-Z]/
                  search.split('').join('.{0,3}')
                end
      rx = Regexp.new(pattern, !case_sensitive)

      text =~ rx
    end

    def should_finish?
      should?('never_finish')
    end

    def should_time?
      should?('never_time')
    end

    private

    def should?(key)
      config = Doing.config.settings
      return true unless config[key].is_a?(Array)

      config[key].each do |tag|
        if tag =~ /^@/
          return false if tags?(tag.sub(/^@/, '').downcase)
        elsif section.downcase == tag.downcase
          return false
        end
      end

      true
    end

    def calc_interval
      done = end_date
      return nil if done.nil?

      start = @date

      t = (done - start).to_i
      t > 0 ? t : nil
    end

    def all_tags?(tags)
      tags.each do |tag|
        return false unless @title =~ /@#{tag}/
      end
      true
    end

    def no_tags?(tags)
      tags.each do |tag|
        return false if @title =~ /@#{tag}/
      end
      true
    end

    def any_tags?(tags)
      tags.each do |tag|
        return true if @title =~ /@#{tag}/
      end
      false
    end

    def split_tags(tags)
      tags = tags.split(/ *, */) if tags.is_a? String
      tags.map { |t| t.strip.sub(/^@/, '') }
    end
  end
end
