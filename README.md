# doing

[![Gem](https://img.shields.io/gem/v/doing.svg)](https://rubygems.org/gems/doing)
[![Travis](https://app.travis-ci.com/ttscoff/doing.svg?branch=master)](https://travis-ci.org/makenew/ruby-gem)
[![GitHub license](https://img.shields.io/github/license/ttscoff/doing.svg)](./LICENSE.txt)

**A command line tool for remembering what you were doing and tracking what
you've done.**

_If you're one of the rare people like me who find this useful, feel free to
[buy me some coffee][donate]._

<!--README-->

The current version of `doing` is <!--VER-->2.1.89<!--END VER-->.

Find all of the documentation in the [doing wiki][wiki].

See [what's new in Doing 2.0][doing 2].

Check out some craziness with Doing in the [iTerm status bar][status bar] and
the [Mac Touch Bar/menu bar][touch bar].

## What and why

`doing` is a basic CLI for adding and listing "what was I doing" reminders in a
[TaskPaper-formatted](https://www.taskpaper.com) text file. It allows for
multiple sections/categories and flexible output formatting.

While I'm working, I have hourly reminders to record what I'm working on, and I
try to remember to punch in quick notes if I'm unexpectedly called away from a
project. I can do this just by typing `doing now tracking down the CG bug`.

If there's something I want to look at later but doesn't need to be added to a
task list or tracker, I can type `doing later check out the pinboard bookmarks
from macdrifter`. When I get back to my computer --- or just need a refresher
after a distraction --- I can type `doing last` to see what the last thing on
my plate was. I can also type `doing recent` (or just `doing`) to get a list of
the last few entries. `doing today` gives me everything since midnight for the
current day, making it easy to see what I've accomplished over a sleepless
night.

Doing has over 30 commands for tracking your status, recording your time, and
analyzing the results.

See [the wiki][wiki] for installation and usage instructions.

## Launchbar/Alfred

The LaunchBar action requires that `doing` be available in
`/usr/local/bin/doing`. If it's not (because you're using RVM or similar),
you'll need to symlink it there. Running the action with Return will show the
latest 9 items from Currently, along with any time intervals recorded, and
includes a submenu of Timers for each tag.

Pressing Spacebar and typing allows you to add a new entry to currently. You an
also trigger a custom show command by typing "show [section/tag]" and hitting
return. Include any command line flags at the end of the string, and if you add
text in parenthesis, it will be processed as a note on the entry.

Point of interest, the LaunchBar Action makes use of the `-o json` flag for
outputting JSON to the action's script for parsing.

<!--GITHUB-->

See the [doing project on BrettTerpstra.com][bt doing] for the download.

<!--END GITHUB-->
<!--JEKYLL
{% download 117 %} 
-->

Evan Lovely has created an [Alfred workflow][] as well.

## Contributing

If you [create a plugin][], custom command, or hook you can share, please
[let me know][contact]. If I get a few plugin contributions, I'll set up a
second repository for them.

Feel free to fork [the repository][github] on GitHub and make pull requests
with changes. Please target the `develop` branch with pull requests.

[bt doing]: https://brettterpstra.com/projects/doing/
[donate]: http://brettterpstra.com/donate/
[github]: https://github.com/ttscoff/doing/
[wiki]: https://github.com/ttscoff/doing/wiki
[doing 2]: https://brettterpstra.com/2021/11/20/doing-2-dot-0/
[status bar]: https://brettterpstra.com/2021/10/15/see-what-youre-doing-in-the-iterm-status-bar/
[touch bar]: https://brettterpstra.com/2021/07/21/crazy-bettertouchtool-touch-bar-simulator/
[create a plugin]: https://github.com/ttscoff/doing/wiki/Creating-Plugins
[contact]: https://brettterpstra.com/contact/
[alfred workflow]: http://www.evanlovely.com/blog/technology/alfred-for-terpstras-doing/

<!--END README-->

---

PayPal link: [paypal.me/ttscoff](https://paypal.me/ttscoff)

## Changelog

See [CHANGELOG.md](https://github.com/ttscoff/doing/blob/master/CHANGELOG.md)
