# frozen_string_literal: true

module Doing
  # Semantic versioning
  class Version
    attr_reader :maj, :min, :patch

    def initialize(string)
      @maj, @min, @patch = version_to_a(string)
    end

    def version_to_a(string)
      raise 'Version not a string' unless string.is_a?(String)

      v = string.match(/(?<maj>\d+)(?:\.(?<min>[\d*?]+))?(?:\.(?<patch>[\d*?]+))?/)

      raise 'Error parsing semantic version string' if v.nil?

      maj = v['maj'].to_i
      min = case v['min']
            when /[*?]/
              v['min'].sub(/(\d+)?[^\d]/, '\1\d+')
            when /^[0-9]+$/
              v['min'].to_i
            end
      pat = case v['patch']
            when /[*?]/
              v['patch'].sub(/(\d+)?[^\d]/, '\1\d+')
            when /^[0-9]+$/
              v['patch'].to_i
            end
      [maj, min, pat]
    end

    def wild?(val)
      val.is_a?(String)
    end

    def compare(other, comp, inclusive: false)
      case comp
      when :older
        if @maj <= other.maj
          if @maj < other.maj
            true
          elsif @maj == other.maj && (other.min.nil? || @min < other.min)
            true
          elsif @maj == other.maj && @min == other.min
            if other.patch.nil?
              false
            else
              inclusive ? @patch <= other.patch : @patch < other.patch
            end
          else
            false
          end
        else
          false
        end
      when :newer
        if @maj >= other.maj
          if @maj > other.maj
            true
          elsif @maj == other.maj && (other.min.nil? || @min > other.min)
            true
          elsif @maj == other.maj && @min == other.min
            if other.patch.nil?
              false
            else
              inclusive ? @patch >= other.patch : @patch > other.patch
            end
          else
            false
          end
        else
          false
        end
      when :equal
        if @maj == other.maj
          if other.min.nil?
            true
          elsif wild?(other.min)
            @min.to_s =~ /^#{other.min}/ ? true : false
          elsif @min == other.min
            if other.patch.nil?
              true
            elsif wild?(other.patch)
              @patch.to_s =~ /^#{other.patch}/ ? true : false
            else
              @patch == other.patch
            end
          else
            false
          end
        end
      end
    end

    def to_s
      "#{@maj}.#{@min || 0}.#{@patch || 0}"
    end
  end
end
