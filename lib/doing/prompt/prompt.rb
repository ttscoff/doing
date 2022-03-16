# frozen_string_literal: true

require_relative 'choose'
require_relative 'fzf'
require_relative 'input'
require_relative 'std'
require_relative 'yn'

module Doing
  # Terminal Prompt methods
  module Prompt
    class << self
      attr_writer :force_answer, :default_answer

      include Color
      include PromptSTD
      include PromptInput
      include PromptYN
      include PromptFZF
      include PromptChoose

      ##
      ## Value to return if prompt is skipped
      ##
      ## @return     Force answer value
      ##
      def force_answer
        @force_answer ||= nil
      end

      ##
      ## If true, always return the default answer without prompting
      ##
      ## @return     [Boolean] default answer
      ##
      def default_answer
        @default_answer ||= false
      end
    end
  end
end
