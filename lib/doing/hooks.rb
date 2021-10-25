# frozen_string_literal: true

module Doing
  # Hook manager
  module Hooks
    DEFAULT_PRIORITY = 20

    @registry = {
      post_config: [],
      post_read: [],
      post_write: []
    }

    # map of all hooks and their priorities
    @hook_priority = {}

    # register hook(s) to be called later, public API
    def self.register(event, priority: DEFAULT_PRIORITY, &block)
      register_one(event, priority_value(priority), &block)
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

      Doing.logger.debug('Hooks:', "Registered #{event} hook") if ENV['DOING_PLUGIN_DEBUG']

      insert_hook event, priority, &block
    end

    def self.insert_hook(event, priority, &block)
      @hook_priority[block] = [-priority, @hook_priority.size]
      @registry[event] << block
    end

    def self.trigger(event, *args)
      hooks = @registry[event]
      return if hooks.nil? || hooks.empty?

      # sort and call hooks according to priority and load order
      hooks.sort_by { |h| @hook_priority[h] }.each do |hook|
        hook.call(*args)
      end
    end
  end
end
