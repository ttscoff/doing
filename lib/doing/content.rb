# frozen_string_literal: true

module Doing
  # Content hash
  class Content < Hash
    def sections
      keys
    end

    def inspect
      sections = []
      items = []
      map do |k, v|
        sections << k
        items.concat(v.items)
      end
      %(#<Doing::Content #{sections.count} sections, #{items.count} items>)
    end
  end
end
