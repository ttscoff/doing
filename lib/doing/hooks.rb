# frozen_string_literal: true

module Doing
  # Hook manager
  module Hooks
    DEFAULT_PRIORITY = 20

    @registry = {
      post_config: [],        # wwid
      post_local_config: [],  # wwid
      post_read: [],          # wwid
      pre_entry_add: [],      # wwid, new_entry
      post_entry_added: [],   # wwid, new_entry
      post_entry_updated: [], # wwid, entry, old_entry
      post_entry_removed: [], # wwid, entry.dup
      pre_export: [],         # wwid, format, entries
      pre_write: [],          # wwid, file
      post_write: []          # wwid, file
    }

    # map of all hooks and their priorities
    @hook_priority = {}

    # register hook(s) to be called later, public API
    def self.register(event, priority: DEFAULT_PRIORITY, &block)
      if event.is_a?(Array)
        event.each { |ev| register_one(ev, priority_value(priority), &block) }
      else
        register_one(event, priority_value(priority), &block)
      end
    end

    # Ensure the priority is a Fixnum
    def self.priority_value(priority)
      return priority if priority.is_a?(Integer)

      PRIORITY_MAP[priority] || DEFAULT_PRIORITY
    end

    # register a single hook to be called later, internal API
    def self.register_one(event, priority, &block)
      unless @registry[event]
        raise Doing::Errors::HookUnavailable, "Invalid hook. Doing only supports #{@registry.keys.inspect}"
      end

      raise Doing::Errors::PluginUncallable, 'Hooks must respond to :call' unless block.respond_to? :call

      Doing.logger.debug('Hook Manager:', "Registered #{event} hook") if ENV['DOING_PLUGIN_DEBUG']

      insert_hook event, priority, &block
    end

    def self.insert_hook(event, priority, &block)
      @hook_priority[block] = [-priority, @hook_priority.size]
      @registry[event] << block
    end

    def self.trigger(event, *args)
      hooks = @registry[event]
      return unless hooks.good?

      # sort and call hooks according to priority and load order
      hooks.sort_by { |h| @hook_priority[h] }.each do |hook|
        hook.call(*args)
      end
    end
  end
end
