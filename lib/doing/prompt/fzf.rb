# frozen_string_literal: true

module Doing
  # Methods for working installing/using FuzzyFileFinder
  module PromptFZF
    ##
    ## Get path to fzf binary, installing if needed
    ##
    ## @return     [String] Path to fzf binary
    ##
    def fzf
      @fzf ||= install_fzf
    end

    ##
    ## Remove fzf binary
    ##
    def uninstall_fzf
      fzf_bin = File.join(File.dirname(__FILE__), '../../helpers/fzf/bin/fzf')
      FileUtils.rm_f(fzf_bin) if File.exist?(fzf_bin)
      Doing.logger.warn('fzf:', "removed #{fzf_bin}")
    end

    ##
    ## Return the path to the fzf binary
    ##
    ## @return     [String] Path to fzf
    ##
    def which_fzf
      fzf_dir = File.join(File.dirname(__FILE__), '../../helpers/fzf')
      fzf_bin = File.join(fzf_dir, 'bin/fzf')
      return fzf_bin if File.exist?(fzf_bin)

      Doing.logger.debug('fzf:', 'Using user-installed fzf')
      TTY::Which.which('fzf')
    end

    ##
    ## Install fzf on the current system. Installs to a
    ## subdirectory of the gem
    ##
    ## @param      force  [Boolean] If true, reinstall if
    ##                    needed
    ##
    ## @return     [String] Path to fzf binary
    ##
    def install_fzf(force: false)
      if force
        uninstall_fzf
      elsif which_fzf
        return which_fzf
      end

      fzf_dir = File.join(File.dirname(__FILE__), '../../helpers/fzf')
      FileUtils.mkdir_p(fzf_dir) unless File.directory?(fzf_dir)
      fzf_bin = File.join(fzf_dir, 'bin/fzf')
      return fzf_bin if File.exist?(fzf_bin)

      prev_level = Doing.logger.level
      Doing.logger.adjust_verbosity({ log_level: :info })
      Doing.logger.log_now(:warn, 'fzf:', 'Compiling and installing fzf -- this will only happen once')
      Doing.logger.log_now(:warn, 'fzf:', 'fzf is copyright Junegunn Choi, MIT License <https://github.com/junegunn/fzf/blob/master/LICENSE>')

      silence_std
      `'#{fzf_dir}/install' --bin --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish &> /dev/null`
      unless File.exist?(fzf_bin)
        restore_std
        Doing.logger.log_now(:warn, 'Error installing, trying again as root')
        silence_std
        `sudo '#{fzf_dir}/install' --bin --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish &> /dev/null`
      end
      restore_std
      unless File.exist?(fzf_bin)
        Doing.logger.error('fzf:',
                           'unable to install fzf. You can install manually and Doing will use the system version.')
        Doing.logger.error('fzf:', 'see https://github.com/junegunn/fzf#installation')
        raise 'Error installing fzf, please report at https://github.com/ttscoff/doing/issues'
      end

      Doing.logger.info('fzf:', "installed to #{fzf}")
      Doing.logger.adjust_verbosity({ log_level: prev_level })
      fzf_bin
    end
  end
end
