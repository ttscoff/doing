# frozen_string_literal: true

module Doing
  module Errors
    PluginException = Class.new(::RuntimeError)

    InvalidPluginType = Class.new(PluginException)
    PluginUncallable = Class.new(PluginException)

    InvalidArgument = Class.new(RuntimeError)
    MissingArgument = Class.new(RuntimeError)
    MissingFile = Class.new(RuntimeError)
    MissingEditor = Class.new(RuntimeError)

    NoEntryError = Class.new(RuntimeError)
    EmptyInput = Class.new(RuntimeError)

    InvalidTimeExpression = Class.new(RuntimeError)
    InvalidSection = Class.new(RuntimeError)
    InvalidView = Class.new(RuntimeError)

    # FatalException = Class.new(::RuntimeError)
    # InvalidPluginName = Class.new(FatalException)
  end
end
