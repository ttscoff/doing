# frozen_string_literal: true

module Status
  def cols
    @cols ||= `tput cols`.strip.to_i
  end

  def progress(msg, idx, total, tail = [])
    status_width = format("> %s [%#{total.to_s.length}d/%d]: ", msg, 0, total).length
    max_width = cols - status_width
    if tail.is_a? Array
      tail.shift while tail.join(', ').length + 3 > max_width
      tail = tail.join(', ')
    end
    tail.ltrunc!(max_width)
    $stderr.print format(
      "#{esc['kill']}#{esc['boldyellow']}> #{esc['boldgreen']}%s #{esc['white']}[#{esc['boldwhite']}%#{@commands.count.to_s.length}d#{esc['boldblack']}/#{esc['boldyellow']}%d#{esc['white']}]: #{esc['boldcyan']}%s#{esc['default']}\r", msg, idx, total, tail
    )
  end

  def status(msg, reset: true, end_char: "\n")
    $stderr.print format("#{esc['kill']}#{esc['boldyellow']}> #{esc['whiteboard']}%s#{esc['default']}%s", msg,
                         reset ? "\r" : end_char)
  end

  def msg(msg, reset: true, color: 'green', end_char: "\n")
    $stderr.print format("#{esc['kill']}#{esc[color]}%s#{esc['default']}%s", msg, reset ? "\r" : end_char)
  end

  def clear
    $stderr.print format("\r#{esc['kill']}")
  end

  def esc
    e = {}
    e['kill'] = "\033[2K"
    e['reset'] = "\033[A\033[2K"
    e['black'] = "\033[0;0;30m"
    e['red'] = "\033[0;0;31m"
    e['green'] = "\033[0;0;32m"
    e['yellow'] = "\033[0;0;33m"
    e['blue'] = "\033[0;0;34m"
    e['magenta'] = "\033[0;0;35m"
    e['cyan'] = "\033[0;0;36m"
    e['white'] = "\033[0;0;37m"
    e['bgblack'] = "\033[40m"
    e['bgred'] = "\033[41m"
    e['bggreen'] = "\033[42m"
    e['bgyellow'] = "\033[43m"
    e['bgblue'] = "\033[44m"
    e['bgmagenta'] = "\033[45m"
    e['bgcyan'] = "\033[46m"
    e['bgwhite'] = "\033[47m"
    e['boldblack'] = "\033[1;30m"
    e['boldred'] = "\033[1;31m"
    e['boldgreen'] = "\033[0;1;32m"
    e['boldyellow'] = "\033[0;1;33m"
    e['boldblue'] = "\033[0;1;34m"
    e['boldmagenta'] = "\033[0;1;35m"
    e['boldcyan'] = "\033[0;1;36m"
    e['boldwhite'] = "\033[0;1;37m"
    e['boldbgblack'] = "\033[1;40m"
    e['boldbgred'] = "\033[1;41m"
    e['boldbggreen'] = "\033[1;42m"
    e['boldbgyellow'] = "\033[1;43m"
    e['boldbgblue'] = "\033[1;44m"
    e['boldbgmagenta'] = "\033[1;45m"
    e['boldbgcyan'] = "\033[1;46m"
    e['boldbgwhite'] = "\033[1;47m"
    e['softpurple'] = "\033[0;35;40m"
    e['hotpants'] = "\033[7;34;40m"
    e['knightrider'] = "\033[7;30;40m"
    e['flamingo'] = "\033[7;31;47m"
    e['yeller'] = "\033[1;37;43m"
    e['whiteboard'] = "\033[1;30;47m"
    e['default'] = "\033[0;39m"
    e
  end
end
