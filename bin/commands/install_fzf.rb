# @@install_fzf
command :install_fzf do |c|
  c.desc 'Force reinstall'
  c.switch %i[r reinstall], default_value: false

  c.desc 'Uninstall'
  c.switch %i[u uninstall], default_value: false, negatable: false

  c.action do |g, o, a|
    if o[:uninstall]
      Doing::Prompt.uninstall_fzf
    else
      Doing.logger.warn('fzf:', 'force reinstall') if o[:reinstall]
      res = Doing::Prompt.install_fzf(force: o[:reinstall])
    end
  end
end
