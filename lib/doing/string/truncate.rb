# frozen_string_literal: true

module Doing
  ##
  ## String truncation
  ##
  module StringTruncate
    ##
    ## Truncate to nearest word
    ##
    ## @param      len   The length
    ##
    def trunc(len, ellipsis: '...')
      return self if length <= len

      total = 0
      res = []

      split(/ /).each do |word|
        break if total + 1 + word.length > len

        total += 1 + word.length
        res.push(word)
      end
      res.join(' ') + ellipsis
    end

    def trunc!(len, ellipsis: '...')
      replace trunc(len, ellipsis: ellipsis)
    end

    ##
    ## Truncate from middle to end at nearest word
    ##
    ## @param      len   The length
    ##
    def truncend(len, ellipsis: '...')
      return self if length <= len

      total = 0
      res = []

      split(/ /).reverse.each do |word|
        break if total + 1 + word.length > len

        total += 1 + word.length
        res.unshift(word)
      end
      ellipsis + res.join(' ')
    end

    def truncend!(len, ellipsis: '...')
      replace truncend(len, ellipsis: ellipsis)
    end

    ##
    ## Truncate string in the middle, separating at nearest word
    ##
    ## @param      len       The length
    ## @param      ellipsis  The ellipsis
    ##
    def truncmiddle(len, ellipsis: '...')
      return self if length <= len
      len -= (ellipsis.length / 2).to_i
      half = (len / 2).to_i
      start = trunc(half, ellipsis: ellipsis)
      finish = truncend(half, ellipsis: '')
      start + finish
    end

    def truncmiddle!(len, ellipsis: '...')
      replace truncmiddle(len, ellipsis: ellipsis)
    end
  end
end
