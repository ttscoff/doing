# frozen_string_literal: true

module Doing
  ##
  ## URL linking and formatting
  ##
  module StringURL
    ##
    ## Turn raw urls into HTML links
    ##
    ## @param      opt   [Hash] Additional Options
    ##
    ## @option opt [Symbol] :format can be :markdown or
    ## :html (default)
    ##
    def link_urls(**opt)
      fmt = opt.fetch(:format, :html)
      return self unless fmt

      str = dup

      str = str.remove_self_links if fmt == :markdown

      str.replace_qualified_urls(format: fmt).clean_unlinked_urls
    end

    ## @see #link_urls
    def link_urls!(**opt)
      fmt = opt.fetch(:format, :html)
      replace link_urls(format: fmt)
    end

    # Remove <self-linked> formatting
    def remove_self_links
      gsub(/<(.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /^https?:/
          m[1]
        else
          match
        end
      end
    end

    # Replace qualified urls
    def replace_qualified_urls(**options)
      fmt = options.fetch(:format, :html)
      gsub(%r{(?mi)(?x:
      (?<!["'\[(\\])
      (?<protocol>(?:http|https)://)
      (?<domain>[\w-]+(?:\.[\w-]+)+)
      (?<path>[\w\-.,@?^=%&;:/~+#]*[\w\-@^=%&;/~+#])?
      )}) do |_match|
        m = Regexp.last_match
        url = "#{m['domain']}#{m['path']}"
        proto = m['protocol'].nil? ? 'http://' : m['protocol']
        case fmt
        when :terminal
          TTY::Link.link_to("#{proto}#{url}", "#{proto}#{url}")
        when :html
          %(<a href="#{proto}#{url}" title="Link to #{m['domain']}">[#{url}]</a>)
        when :markdown
          "[#{url}](#{proto}#{url})"
        else
          m[0]
        end
      end
    end

    # Clean up unlinked <urls>
    def clean_unlinked_urls
      gsub(/<(\w+:.*?)>/) do |match|
        m = Regexp.last_match
        if m[1] =~ /<a href/
          match
        else
          %(<a href="#{m[1]}" title="Link to #{m[1]}">[link]</a>)
        end
      end
    end
  end
end
