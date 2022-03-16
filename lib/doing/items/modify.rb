# frozen_string_literal: true

module Doing
  class Items < Array
    ##
    ## Delete an item from the index
    ##
    ## @param      item  The item
    ##
    def delete_item(item, single: false)
      deleted = delete(item)
      Doing.logger.count(:deleted)
      Doing.logger.info('Entry deleted:', deleted.title) if single
      deleted
    end

    ##
    ## Update an item in the index with a modified item
    ##
    ## @param      old_item  The old item
    ## @param      new_item  The new item
    ##
    def update_item(old_item, new_item)
      s_idx = index { |item| item.equal?(old_item) }

      raise ItemNotFound, 'Unable to find item in index, did it mutate?' unless s_idx

      return if fetch(s_idx).equal?(new_item)

      self[s_idx] = new_item
      Doing.logger.count(:updated)
      Doing.logger.info('Entry updated:', self[s_idx].title.trunc(60))
      new_item
    end
  end
end
