# doing

**A command line tool for remembering what you were doing and tracking what you've done.**

_If you're one of the rare people like me who find this useful, feel free to contribute to my [GitTip fund](https://www.gittip.com/ttscoff/) or just [buy me some coffee](http://brettterpstra.com/donate)._

## What and why

`doing` is a basic CLI for adding and listing "what was I doing" reminders in a [TaskPaper-formatted](http://www.hogbaysoftware.com/products/taskpaper) text file. It allows for multiple sections/categories and flexible output formatting.

While I'm working, I have hourly reminders to record what I'm working on, and I try to remember to punch in quick notes if I'm unexpectedly called away from a project. I can do this just by typing `doing now tracking down the CG bug`. 

If there's something I want to look at later but doesn't need to be added to a task list or tracker, I can type `doing later check out the pinboard bookmarks from macdrifter`. When I get back to my computer --- or just need a refresher after a distraction --- I can type `doing last` to see what the last thing on my plate was. I can also type `doing recent` (or just `doing`) to get a list of the last few entries. `doing today` gives me everything since midnight for the current day, making it easy to see what I've accomplished over a sleepless night.

_Side note:_ I actually use the library behind this utility as part of another script that mirrors entries in [Day One](http://dayoneapp.com/) that have the tag "wwid." I can use the hourly writing reminders and enter my stuff in the quick entry popup. Someday I'll get around to cleaning that up and putting it out there.

## Installation

    $ [sudo] gem install doing

Only use `sudo` if your environment requires it. If you're using the system Ruby on a Mac, for example, it will likely be necessary. If `gem install doing` fails, then run `sudo gem install doing` and provide your administrator password.

See the [support](#support) section below for troubleshooting details.

## The "doing" file

The file that stores all of your entries is generated the first time you add an entry with `doing now` (or `doing later`). By default the file is created in "~/what_was_i_doing.md", but this can be modified in the config file.

The format of the "doing" file is TaskPaper-compatible. You can edit it by hand at any time (in TaskPaper or any text editor), but it uses a specific format for parsing, so be sure to maintain the dates and pipe characters. 

Notes are anything in the list without a leading hyphen and date. They belong to the entry directly before them, and they should be indented one level beyond the parent item. The `now` and `later` commands don't currently make it possible to add notes at the time of entry creation, but I have scripts that do it and will incorporate them soon.

## Configuration

A basic configuration looks like this:

    ---
    doing_file: /Users/username/Dropbox/nvALT2.2/?? What was I doing.md
    current_section: Currently
    default_template: '%date: %title%note'
    default_date_format: '%Y-%m-%d %H:%M'
    templates:
      default:
        date_format: '%Y-%m-%d %H:%M'
        template: '%date | %title%note'
        wrap_width: 0
      today:
        date_format: '%_I:%M%P'
        template: '%date: %title%odnote'
        wrap_width: 0
      last:
        date_format: '%_I:%M%P on %a'
        template: '%title (at %date)%odnote'
        wrap_width: 0
      recent:
        date_format: '%_I:%M%P'
        template: '%date > %title%odnote'
        wrap_width: 50
    :include_notes: true


The config file is stored in "~/.doingrc", and is created on the first run. 

The one thing you'll probably want to adjust is the file that the notes are stored in. That's the `doing_file` key:

    doing_file: /Users/username/Dropbox/nvALT2.2/?? What was I doing.md

I keep mine in my nvALT folder for quick access and syncing between machines. If desired, you can give it a `.taskpaper` extension to make it more recognizable to other applications. (If you do that in nvALT, make sure to add `taskpaper` as a recognized extension in preferences).

You can rename the section that holds your current tasks. By default, this is "Currently," but if you have some other bright idea, feel free:

    current_section: Currently

The config also contains templates for various command outputs. Include placeholders by placing a % before the keyword. The available tokens are:

- `%title`: the "what was I doing" entry line
- `%date`: the date based on the template's "date_format" setting
- `%shortdate`: a custom date formatter that removes the day/month/year from the entry if they match the current day/month/year
- `%note`: Any note in the entry will be included here, a newline and tabs are automatically added.
- `%odnote`: The notes with a leading tab removed (outdented note)
- `%hr`: a horizontal rule (`-`) the width of the terminal
- `%hr_under`: a horizontal rule (`_`) the width of the terminal
- `%[color]`: color can be black, red, green, blue, yellow, magenta, cyan or white
  - you can prefix "bg" to affect background colors (%bgyellow)
  - prefix "bold" and "boldbg" for strong colors (%boldgreen, %boldbgblue)

Date formats are based on Ruby [strftime](http://www.ruby-doc.org/stdlib-2.1.1/libdoc/date/rdoc/Date.html#method-i-strftime) formatting.

My normal template for the `recent` command looks like this:

    recent:
      date_format: '%_I:%M%P'
      template: '%date > %title%odnote'
      wrap_width: 88

And it outputs:
    
    $ doing recent 3
     4:30am > Made my `console` script smarter...
        Checks first argument to see if it's a file, if it is, that's the log

        Else, it checks the first argument for a ".log" suffix and does a search in the user
        application logs with `find` for it.

        Otherwise, system.log.

        I also made an awesome Cope wrapper for it...
    12:00pm > Working on `doing` again.
    12:45pm > I think this thing (doing) is ready to document and distribute
    $ 

You can get pretty clever and include line breaks and other formatting inside of double quotes. If you want multiline templates, just use "\n" in the template line and after the next run it will be rewritten as proper YAML automatically.

For example, this block:

    recent:
      date_format: '%_I:%M%P'
      template: "\n%hr\n%date\n > %title%odnote\n%hr_under"
      wrap_width: 100

will rewrite to:

    recent:
      date_format: '%_I:%M%P'
      template: |2-

        %hr
        %date
         > %title%odnote
        %hr_under
      wrap_width: 100

and output my recent entries like this:

    $ doing recent 3
    -----------------------------------------------------------------------
     4:30am
     > Made my `console` script smarter...
        Checks first argument to see if it's a file, if it is, that's the log

        Else, it checks the first argument for a ".log" suffix and does a search in the user application
        logs with `find` for it.

        Otherwise, system.log.

        I also made an awesome Cope wrapper for it...
    _______________________________________________________________________

    -----------------------------------------------------------------------
    12:00pm
     > Working on `doing` again.
    _______________________________________________________________________

    -----------------------------------------------------------------------
    12:45pm
     > I think this thing (doing) is ready to document and distribute
    _______________________________________________________________________

    $ 

### Custom views

You can create your own "views" in the `~/.doingrc` file and view them with `doing view view_name`. Just add a section like this:

    views:
      old:
        section: Old
        count: 5
        wrap_width: 0
        date_format: '%F %_I:%M%P'
        template: '%date | %title%note' 

You can add additional custom views, just nest them under the "views" key (indented two spaces from the edge). Multiple views would look like this:

    views:
      later:
        section: Later
        count: 5
        wrap_width: 60
        date_format: '%F %_I:%M%P'
        template: '%date | %title%note'
      old:
        section: Old
        count: 5
        wrap_width: 0
        date_format: '%F %_I:%M%P'
        template: '%date | %title%note' 

The "section" key is the default section to pull entries from. Count and section can be overridden at runtime with the `-c` and `-s` flags.

You can add new sections with `done add_section section_name`. You can also create them on the fly by using the `-s section_name` flag when running `doing now`. For example, `doing now -s Misc just a random side note` would create the "just a random side note" entry in a new section called "Misc."

Regarding colors, you can use them to create very nice displays if you're outputting to a color terminal. Example:

    color:
      date_format: '%F %_I:%M%P'
      section: Currently
      count: 10
      wrap_width: 0
      template: '%boldblack%date %boldgreen| %boldwhite%title%default%note'

Outputs: 

![](http://ckyp.us/XKpj+)

## Usage:

    doing [global options] command [command options] [arguments...]

### Global options:

    --[no-]notes        - Output notes if included in the template (default: enabled)
    --version           - Display the program version
    --help              - Show help message and usage summary

### Commands:

    help     - Shows a list of commands or help for one command (`doing help now`)

#### Adding entries:

    now      - Add an entry
    later    - Add an item to the Later section
    done     - Add an entry tagged with @done(YYYY-mm-dd hh:mm)

#### Displaying entries:

    show     - List all entries
    recent   - List recent entries
    today    - List entries from today
    last     - Show the last entry

#### Sections

    sections - List sections
    choose   - Select a section to display from a menu

#### Utilities

    archive  - Move all but the most recent 5 entries to the Archive section
    config   - Edit the default configuration

---

### Troubleshooting

#### Errors after "Successfully installed..."

If you get errors in the terminal immediately after a message like:

    Successfully installed doing-x.x.x
    2 gems installed

...it may just be documentation related. If running `doing` works, you can ignore them. If not, try running the install command again with `--no-document`:

    $ gem install --no-document doing

#### Command not found

If running `doing` after a successful install gives you a "command not found" error, then your gem path isn't in your $PATH, meaning the system can't find it. To locate the gem and link it into your path, you can try this:

    cd $GEM_PATH/bin
    ln -s doing /usr/local/bin/

Then try running `doing` and see if it works.

#### Encoding errors

Ruby is rife with encoding inconsistencies across platforms and versions. Feel free to file issues (see below).

#### Support

I'm not making any money on `doing`, and I don't plan to spend a lot of time fixing errors on an array of operating systems and platforms I don't even have access to. You'll probably have to solve some things on your own.

That said, you can get support from other users (and occasionally me) on GitHub. If you run into a replicatable issue in your environment, please [post an issue](https://github.com/ttscoff/doing/issues) and include your platform, OS version, and the result of `ruby -v`, along with a copy/paste of the error message.

Please try not to email me directly about GitHub projects.
