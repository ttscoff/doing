### 2.1.34

2022-02-20 06:38

#### IMPROVED

- --only_timed for today
- --tag_order for commands missing with --totals output that were missing it
- Tag and search filters for on, since, today and yesterday
- --only_timed filter for yesterday

#### FIXED

- Don't return a duration or interval for entries configured as never_time or never_finish
- --from time filter for yesterday

### 2.1.33

2022-02-18 12:09

#### FIXED

- Major fixes for completion scripts, especially zsh

### 2.1.32

2022-02-18 08:34

#### NEW

- `doing config set --local` flag to force updates to local .doingrc, creating if it doesn't exist, and bypassing menu selection

#### IMPROVED

- `doing tag_dir` will not allow duplicate tags or tags that are already applied by a config higher up the hierarchy
- `doing tag_dir` will force updates to .doingrc in the current directory rather than offering a menu

#### FIXED

- When running without subcommand, e.g. `doing this thing`, the first word was being lost
- Remove blank lines when running `doing changes --changes --md` (output changes only in Markdown format)

### 2.1.31

2022-02-17 12:59

#### NEW

- `doing completion install SHELL` will copy the default completion scripts to your ~/.local/share/doing folder and offer to symlink them to autoload directories. These scripts are generated with each release but will not include any custom commands or plugins in the completions.
- `doing completion` now uses subcommands, `generate` and `install`. The install command will write default scripts to ~/.local/share/doing/completion and link them into the appropriate autoload directory for the shell. The generate command will create new scripts that include any custom commands and plugins.
- Convenience methods for plugins getting and setting configuration options using dot key paths (`Doing.setting('plugins.myplugin.setting')` and `Doing.set('plugins.myplugin.setting', value)`)

#### IMPROVED

- When generating completion scripts using `doing completion --file FILE_PATH`, if the file specified is not in an auto-load directory for the shell type, offer to symlink the output to an appropriate directory
- Update examples in `doing help completion` and its subcommands
- Move in-memory configuration into a module variable so it can be persisted/accessed outside of a WWID object using `Doing.config`
- Clean up/update `wiki` example command

#### FIXED

- Don't output empty notes as empty brackets in JSON output (also fixes the LaunchBar view of recent entries)
- Error in `--back` flag for `doing again`
- Don't try to finish items already marked @done in `doing again`
- Generating scripts using `doing completion` would fail if the terminal running it was narrow enough to wrap help output

### 2.1.29

2022-02-14 12:42

#### IMPROVED

- `doing changes --interactive` will load up a changelog viewer using fzf. Because it makes me happy, that's why.

### 2.1.28

2022-02-14 11:39

#### FIXED

- Lines merging in `doing changes --changes` output

### 2.1.27

2022-02-14 06:04

#### NEW

- `doing finish --update` will overwrite any existing @done tag with a new date (current time or set with `--at` or `--back`)

#### IMPROVED

- Code refactoring and cleanup
- Include release dates in `doing changes` output when available
- Allow various naming conventions for %color strings in templates. Now `boldwhite`, `brightwhite`, `bg_bold_cyan`, and `bold_bg_cyan` all work (for example)
- Common flags (e.g. --search, --tag) found on multiple commands consolidated and help descriptions matched
- `commands_accepting` now accepts multiple arguments and a `--bool` flag
- `changes` command can now output changes only (no version numbers) and defaults to raw Markdown if not a TTY or the `--md` flag is used
- `doing archive` now accepts `--after` and `--from` date filters

#### FIXED

- Some flag descriptions in help
- Editor detection

### 2.1.26

2022-01-23 16:14

#### NEW

- Use plugins.hidden_commands in configuration to disable any command (array of command names). Note that some commands use aliases and the first name should be used.
- `doing commands [add|remove]` allows interactive enabling and disabling of default and custom commands

#### IMPROVED

- Moved all commands into separate files for management

#### FIXED

- Changelog command regex too greedy when parsing changelog

### 2.1.25

2022-01-23 09:25

### 2.1.24

2022-01-22 17:27

#### IMPROVED

- Minor update to Fish completion script

#### FIXED

- Changelog formatting issue

### 2.1.23

2022-01-22 15:52

#### NEW

- All display commands (except view) now accept `--config_template TEMPLATE_KEY` to override that commands default template.
- Display commands accept `--template`, which takes a template string containing %placeholders and overrides the commands default template output. Affects grep, last, on, recent, show, since, today, yesterday

#### IMPROVED

- With complete examples in the help output for most commands, `doing help` almost always requires scrolling up. It now automatically paginates using your system $PAGER (or best detected option).
- `doing tags` takes a MAX_COUNT argument to limit results when searching
- `doing tags --line` flag to output tags in a single line
- Mostly for my own use, `doing changes` (which views the changelog) now accepts `--lookup VERSION` and `--search SEARCH_PATTERN`
- `doing changes --lookup` accepts `"< 2.1 > 2.0"`, `"2.1.10-2.2"`, a specific version, or a version number with wildcards
- When registering hooks, you can pass an array to register a block for multiple events, assuming the events provide the same block arguments (like post_entry_added and post_entry_updated)

#### FIXED

- Running `--tag "@doing"` wouldn't work where `--tag "doing"` would. Now properly ignoring @ symbols

### 2.1.22

2022-01-21 14:53

### 2.1.21

2022-01-20 12:05

#### FIXED

- Custom types not available to custom commands

### 2.1.20

2022-01-20 11:49

#### NEW

- Autotag option for interactive `doing select` menu
- (Breaking change) Made the later command an optional plugin, see wiki for how to install (and create) custom commands
- Config setting doing_file_sort (asc or desc) determines the sort order of entries in the actual Doing file. Has no effect on other operations, just allows you to store the file with newest entries at top (desc) or bottom (asc).

#### IMPROVED

- Autotag improvements
- If doing is run without a command but with arguments, execute it as if you'd run `doing now`, passing the arguments to that. So you can just write "doing this thing" instead of "doing now this thing", as long as the first word of the arguments is not a recognized command.

#### FIXED

- `doing again` should only mark the original repeating entry @done, not search for the last unfinished entry
- Error when using `doing finish --auto`
- `doing on wed` when today is wednesday not returning results
- Using `config set` with a false value deleted the key from config
- `config set` with true or false value was inserting a quoted string
- Entries were not being sorted (at all) within sections when writing the Doing file

### 2.1.19

2022-01-18 08:40

#### FIXED

- Search highlighting error with some pattern searches
- Reverse sort of items in menu from `--interactive` flags
- Nil error when `--interactive` was called without search results

### 2.1.18

Build automation test

### 2.1.17

2022-01-18 07:26

#### NEW

- `--hilite` option for `doing search` to highlight matches in search results (terminal output only)
- `--hilite` flag for `show` and `view` to highlight results when used with `--search`

#### IMPROVED

- Show preview of up to 5 items when confirming a delete operation so you actually know what you're deleting
- Allow `--ask` when creating new entry via STDIN pipe
- Tab completion for known tags when creating an entry interactively
- Add purple as an alias for magenta in template colors

#### FIXED

- Clear STDIN before requesting input

### 2.1.16

2022-01-18 02:45

#### NEW

- `doing done --from "3pm to 3:15pm"` to set start and end times with natural language string

#### IMPROVED

- Running `doing tag` without arguments takes command line input
- If `doing now` or `doing later` are run without arguments, interactively request necessary information (you can still use `--editor` to edit in your preferred editor)
- Tab completion for tags when entering at prompt
- Use readline when requesting input text, better editing features
- `doing done --at` no longer overrides `--back`

#### FIXED

- `doing select` -> output formatted empty output
- Sort items by date when using `doing select --editor` (was loading in selection order instead)
- Ruby 2.7 error in template output (.empty? on FalseClass)
- Don't add empty entry when cancelling `--editor`
- Batch editing bugs

### 2.1.15

2022-01-17 07:25

#### NEW

- When completing an entry, if the elapsed time would be greater than a (configurable) amount, doing will now ask for confirmation and allow you to enter a new duration before setting the @done date

#### IMPROVED

- When entering intervals, you can now use 1h30m in addition to 1.5h or 90m
- Date expansion works in more circumstances
- You can include date tags with natural language values when adding tags via `doing select`

#### FIXED

- Tags containing values with spaces no longer cause errors

### 2.1.14

#### NEW

- All commands that accept `--note` now accept `--ask`, which requests input via readline after creating the note. Multiple lines are allowed, hit return twice to end editing. Works alongside `--note` and `--editor`

#### IMPROVED

- Implement `--search` and `--from` filtering for import plugins
- UTC format date strings in select menus for consistency (was relative date formatting)
- Don't populate the fzf search with `--search`, it's already filtered. Separated `--query` from `--search` if you do want to populate the query string in addition to `--search` filtering
- When showing relative dates, don't include the year if the date is the previous year but a later month than the current month (less than a year old)
- When using `--editor` while adding an entry, include any note specified on the command line or via `--ask` for further editing

### 2.1.13

#### NEW

- `--val` flag for all display commands, allows tag value queries. Tag values are contained in parenthesis after the tag, e.g. @progress(50). Queries look like `--val "done < two weeks ago"`, "project *= oracle" or "progress >= 50". Wildcards allowed in value, comparators can be <, >, <=, >=, ==, *= (contains), ^= (begins with), $= (ends with). Numeric and date comparisons are detected automatically. Text comparisons are case insensitive. `--val` can be used multiple times in a command and you can use `--bool` to specify AND, OR, or NOT (default AND)
- `doing tag` now accepts a `--value` flag to define a value for a single tag, e.g. @tag(value)

#### FIXED

- `doing last --editor` errors

### 2.1.12

#### NEW

- Tag_dir command creates/updates .doingrc files in the current directory with default_tags values. Then all entries created within that directory (or subdirs) get tagged with that value.
- Synonym triggers allow `*` and `?` wildcards
- Add `--delete` flag for `doing last` to delete last entry
- `--delete` and `--editor` flags for `doing search`, batch edit and delete
- Example hook to add new entries containing a certain tag to Day One
- New hooks: pre_entry_add, post_entry_added, post_entry_updated, post_entry_removed, pre_export

#### IMPROVED

- If you need to use a colon in an autotag transform pattern, you can split with double colon, e.g. pattern::replacement
- Arrays defined in local configurations merge with main config instead of overwriting

#### FIXED

- `doing tags --interactive` wasn't showing menu

### 2.1.10

#### NEW

- `--age` (oldest|newest) option for view command

### 2.1.9

#### IMPROVED

- Only attempt to install fzf if it doesn't exist on the system. In case of errors, this means a user can manually install fzf and still be able to access `--interactive` options

#### FIXED

- Rotate command only archiving half of requested items
- Frozen string error in doing import plugin

### 2.1.8

#### NEW

- Hidden command `doing commands_accepting` which shows all commands that accept a given option, e.g. `doing commands_accepting search` shows all commands that take a search filter
- Hidden command `doing changelog` which outputs a paginated, formatted version of the change history.

#### IMPROVED

- The output of `doing template --list` now shows the file type of each template
- Output templates can now be saved to a default location/filename using `doing template html --save`

#### FIXED

- Error running `doing recent` on certain older ruby versions

### 2.1.6

#### NEW

- `doing redo` undoes a redo
- `doing undo -i` offers a list of available versions for selection
- Multiple undo. Every time a command modifies the doing file, a backup is written. Running `doing undo` repeatedly steps back through history, `doing undo 5` jumps back 5 versions
- When resetting via `doing select`, prompt for a date string
- `doing reset` accepts a date string argument to use as start date instead of current time if provided
- `doing tags` lists tags used in any/all sections, sortable, with or without frequency counts
- `doing show --menu` offers an interactive menu for selecting section and tag filters
- All commands that accept a `--tag` filter can now handle wildcards in the tag names. * to match any number of characters, ? to match a single character.
- New boolean type for tag searches, PATTERN (which is now the default). Combine tags using symbols to create more complex boolean searches, e.g. "doing +coding -work"
- You can now define `date_tags` in config, an array of tags/patterns that will be recognized when parsing for natural language dates which are converted when saving new entries
- `--search` strings can contain quoted phrases and use +/- to require or ban terms, e.g. `--search 'doing +coding -writing'
- Interactive option for redo command
- Plugins for Day One export

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump
- Matching algorithm can be configured in settings
- All template placeholders can now use the "printf" formatting that %title and %note have, allowing for padding, prefixes, etc.
- Move default locations for doing file and backups to ~/.local/share/doing
- `doing show --menu` will only offer tags that exist after any tag/search filters have been run
- `doing show @tag` with `--menu` will first filter by the @tag, then do an OR search for tags selected from the menu

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed
- Preserve colors when wrapping text to new lines
- Tag highlighting errors
- Template options specified in views were being overriden by options in templates. View config now has precedence, but will fall back to template config for missing keys

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed

### 2.1.3

#### NEW

- BREAKING CHANGE: custom classes for Section (hash) and Items (Array). @content is still a regular Hash. Sections have methods :original and :items. This will affect plugins as wwid.content[section][:items] is now wwid[section].items (same for :original)
- `doing config set -r key.path` will delete a key from any config file, removing empty parent keys
- `config list` will list detected .doingrc files and the main config file in order of precedence - refactoring
- When modifying start dates or @done dates via an editor command, natural language strings can be used and will be parsed into doing-formatted dates automatically
- When editor is invoked, entry titles include start date, which can be modified
- `--before`, `--after`, and `--from` date filters for select command
- `--from` flag for `doing today` and `doing yesterday`, filter by time range
- `--from` flag for `doing search`, filter by date/time range
- Commands that accept `--before`, `--after`, and `--from` can now filter on time ranges. If the date string given contains only a time (no day or date), it will be interpreted as a time range, meaning the date isn't filtered, but only entries within the time range are shown/processed
- Add %duration placeholder to template variables
- Add `interval_format` setting to config (applies to root or any view/template) to set intervals/durations to human (2h 15m) or text (00:02:15)
- Add `duration` key to config (root or view/template). If set to true, will display durations by default (no need for `--duration`)
- Most display commands now have a `--duration` flag that will display an elapsed time if the entry is not marked @done

#### IMPROVED

- Config -o raw outputs value as YAML if result is a Hash/mapping, unquoted string if a single value, comma-separated list if it's an Array.
- Config -o json no longer includes key, only value.
- System agnostic method for checking available executables (pager, editor)
- Using `config set` and selecting a local config will no longer write the entire config to the local .doingrc. Instead, a nested path to the particular setting will be added to the config file.
- Config set will create missing keys. Fuzzy matching will work until the path fails, then path elements after that point will be added as verbatim keys to the specified configuration (with confirmation)
- Make menus only as tall as needed, so 5 options don't take up the whole screen
- Better word wrap for long note lines

#### FIXED

- `finish --took 60m` is supposed to backdate the start date if needed to finish at the current time and maintain an elapsed time
- If an editor was specified for config (or default as fallback) with command line options (e.g. `emacs -nw`), Doing would fail to recognize that the executable was available.

### 2.0.25

#### NEW

- `doing config set` to set single config values from command line
- BREAKING CHANGE: Moves ~/.doingrc to ~/.config/doing/config.yml
- BREAKING CHANGE: convert config flags to subcommands, e.g. `doing config --udpate` => `doing config update`, and `doing config --dump` => `doing config dump`

### 2.0.24

- include fzf source directly, in case git isn't installed
- fall back to installing fzf with sudo on error

### 2.0.20

#### IMPROVED

- completion script generator refactor and progress bars

#### FIXED

- compile fzf for current operating system

### 2.0.19

#### FIXED

- Remove any coloring before writing to doing file

### 2.0.18

#### FIXED

- Escape codes being included in doing file

### 2.0.17

#### IMPROVED

- Improvements to %title formatting and wrapping

### 2.0.16

- Test release to validate git flow automation

### 2.0.13

#### FIXED

- Remove amatch gem dependency due to compatibility issues with Windows systems (also removes `--fuzzy` option from all search commands)

### 2.0.11

#### NEW

- Append `/r` to tag transforms to replace original tag

#### FIXED

- Autotag tag transform fixes

### 2.0.10

#### NEW

- Add 'timer_format' config with 'human' option for tag totals
- If `doing view` and `doing show` are confused, offer option to run the other command
- `doing completion` to generate shell completion scripts for zsh, bash, and fish
- `--search` and `--not` for cancel command
- `--case` flag for commands with `--search`. Can be (c)ase-sensitive, (i)nsensitive, or (s)mart (default smart, case insensitive unless search string contains uppercase letters)
- Add `--exact` flag to all commands with `--search` flag to force exact matching without requiring single quote prefix
- Add `--not` flag to all commands with filters (`--tag`, `--search`, `--before`, etc.) to negate the filter and return entries NOT matched

#### IMPROVED

- More command line feedback
- Error formatting and output
- Add subcommand completion for `doing help` in fish shell
- Logging and error handling

#### FIXED

- Zsh completion not outputting results
- Remove `--[no]` from non-negatable options
- `doing plugins -t export -c` not outputting columns
- View config not respecting tag_order setting
 
### 2.0.3.pre

#### NEW

- Import calendar events from Calendar.app on macOS
- `doing config --update` will add newly added config keys to your existing config file (handy with plugins that define their own config keys)
- Add %idnote template placeholder for "indented note" (entire note indented one tab)
- (loosely printf-esque) formatting options for `%note` template placeholder
- `--interactive` mode to act on results of `doing grep`
- Printf formatting for title and date
- Doing import plugin
- Plugins command to list plugins
- `--dump` option for `doing config` to output a key.path config key as JSON, YAML, or raw output
- `--no-color` global flag
- Log levels, with `--quiet` and `--verbose` global flags
- Convert CLI messaging to Logger-based system
- Use DOING_DEBUG, DOING_QUIET, or DOING_LOG_LEVEL environment variables to specify log levels before configuration is read
- Hooks, register plugins to run based on events
- --[no-]pager and paginate: config option to enable paging output
- Never_finish and never_time config options to prevent items matching tags/sections from ever receiving @done (never_finish) or @done timestamp (never_time) - More configuration refactoring

#### IMPROVED

- Timeline output formatting
- Major plugin architecture refactoring
- Fix regression where notes stored in doing file were outdented, breaking TaskPaper compatibility
- When accepting a date filter, allow end date to be in the future
- If an edited item has no changes, don't update/output notification - Don't start with query when using grep `--interactive`
- Select menu item formatting
- Output wrapping for terminal display
- Redirect warn to STDOUT when run with `--stdout`
- Fish autocomplete
- `--config_file` global flag deprected, now uses $DOING_CONFIG environment variable so that config overrides can be available before the initial configuration is run
- When `--stdout` or not a TTY, no color or output formatting
- Highlight tags when showing results. Because it looks nice.
- `--tag` and `--search` for `doing note`
- View/section fuzzy guessing
- Error reporting
- If `doing config` finds local doingrc files, offers a menu for editing
- More filtering options for `doing finish`
- Doing done accepts `--unfinished` flag to finish last entry not marked @done (instead of last entry)
- Doing done accepts `--note` flag to append a note when completing an entry

#### FIXED

- Multi-word unquoted arguments to add_section being truncated
- Show `--from` with date span
- Handling of arbitrary times in natural language dates
- Backward scope of since command with arbitrary times
- `doing rotate --keep` wasn't respecting keep value

### 1.0.93

#### FIXED

- Gemfile error

### 1.0.91

#### NEW

- "taskpaper" format available for all output options
- "markdown" format available for all output commands (GFM-style task list, customizable template)
- `--rename` option for tag command to replace tags
- `--regex` option for tag command, for `--remove` and `--rename`

### 1.0.90

#### IMPROVED

- doing finish `--auto` now pulls from all sections, not just the section of the target entry

#### FIXED

- Minor fix for shell command in doing select
- Fix for doing finish `--auto` when matched item is last in list

### 1.0.89

#### NEW

- Pretty print JSON output
- `--no-menu` option for select command to use `--query` as a filter and act on matching entries without displaying menu

### 1.0.88

#### IMPROVED

- Add `--before` and `--after` time search to yesterday command
- Add `--before` and `--after` date search to search/grep command
- Add `--tag_order` to yesterday command

### 1.0.87

#### IMPROVED

- Add leading spaces to make %shortdate align properly, at least for the last week
- Add `--tag`, `--bool`, and `--search` to view command
- Add `--before` and `--after` date search to view command
- Add `--before` and `--after` date search to show command
- Add `--before` and `--after` time search to today command
- Add `--search` filter to show command
- More alignment/formatting fixes for %shortdate

### 1.0.86

#### IMPROVED

- Add `count` config option for templates->recent

### 1.0.85

#### IMPROVED

- Add `--before` DATE_STRING to archive and rotate commands
- Only create on rotate file per day, merge new entries into existing file

#### FIXED

- Fix `--auto` for finish command

### 1.0.84

#### NEW

- `rotate` command for archiving entries to new file

#### FIXED

- Fixed current_section config key not being honored in some commands

### 1.0.83

#### FIXED

- Fixes for `doing view` options, additional config keys for views

### 1.0.82

#### FIXED

- Bugfixes

### 1.0.81

#### IMPROVED

- fzf menu improvements
- allow multiple selections `doing select` action menu

### 1.0.80

#### IMPROVED

- Convert all menus to fzf screens

### 1.0.79

#### IMPROVED

- Wildcard tag removal using `doing select -t "tag*" -r`
- fzf menu display polish

#### FIXED

#### FIXED

- Gem missing fzf

### 1.0.78

#### IMPROVED

- If no action is specified with select command, an interactive menu is
presented
- add output action select command with formatting and save options
- Don't link URLs in html output that don't have a protocol

### 1.0.76

#### IMPROVED

- Refine editing multiple selections (doing select)

### 1.0.74

#### NEW

- Add `--tag` and `--search` flags to tag command to tag all entries matching search terms
- Add since command, which is the same as `doing on tuesday to now` but `doing since tuesday` just feels more intuitive. 

### 1.0.73

#### FIXED

- Fix for timeline output

### 1.0.72

#### NEW

- Add `doing select` to show menu of all tasks, searchable with fuzzy matching and the ability to perform certain tasks on multiple selections.

### 1.0.71

#### FIXED

- Fix for template command not working at all

### 1.0.70

#### FIXED

- Fix for `doing done --took 30m` setting the wrong @done timestamp when completing previous item

### 1.0.69

#### IMPROVED

- Add `--unfinished` option to finish and cancel commands

### 1.0.68

#### FIXED

- Fix error in `doing show --sort` argument parsing

### 1.0.67

#### FIXED

- Gem packaging error

### 1.0.66

#### IMPROVED

- More flexible boolean specification, can be: all, and, any, or, not, or none

#### FIXED

- Fix for some long flags being interpreted as arrays instead of strings
- Fix for archive command not removing original entries from archived section

### 1.0.65

#### IMPROVED

- Prevent duplicates/overlapping entries when importing

### 1.0.64

#### NEW

- Initial import feature for Timing.app reports

### 1.0.63

#### IMPROVED

- If `doing done --took=X` results in completion date greater than current time, use current time as completion date and backdate the entry's timestamp to fit

### 1.0.62

#### FIXED

- `doing done` with `--took=` and without `--back=` should set end time to start date plus `--took` value

### 1.0.61

#### IMPROVED

- Add `--search` filter to `doing archive`

### 1.0.60

#### FIXED

- Default value for `doing again --bool` was ALL, should be AND

### 1.0.59

#### IMPROVED

- Improvements to `doing again --tag=` functionality

### 1.0.58

#### IMPROVED

- Finish previous task if `doing again` and not already completed

### 1.0.57

#### IMPROVED

- Unit tests

### 1.0.56

#### IMPROVED

- Tag command tests

#### FIXED

- Doing not reading per-directory .doingrc configs

### 1.0.55

#### NEW

- Added config_editor_app setting to config so you can have
- A parenthetical at the end of an entry title becomes an attached
- `--editor` flag for `doing last` to edit last entry
- `--tag=` flag to filter `doing last` by tag
- `--search=` to filter `doing last` by text/regex search
- `--search=` for `doing finish`, finish last X entries matching search
- Add `tags_color` as a primary config key to highlight @tags in displayed entries

#### IMPROVED

- Clean up command line help
- `--editor` improvements for all commands that use it

#### FIXED

- Doing finish `--took` throwing error
- Doing tag `--remove` was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date

#### IMPROVED

- Add `--no-color` option to view command
- Add `--tag` to show for compatibility

#### FIXED

- Error running finish without `--tag` flag
- `--archive` flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry

#### FIXED

- `--archive` flag on finish, done, and cancel causing error

### 1.0.49

#### FIXED

- Fix for missing date on @done tags

### 1.0.48

#### FIXED

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

#### IMPROVED

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

#### IMPROVED

- Code cleanup

### 1.0.45

#### IMPROVED

- Only execute run_after script if changes are written

### 1.0.44

#### IMPROVED

- Remove unnecessary console logging

### 1.0.43

#### NEW

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

#### FIXED

- Fix note indentation in doing file

### 1.0.41

#### FIXED

- Fix for repeated backreferences in tag transform

### 1.0.40

#### IMPROVED

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

#### NEW

- Tag transforms
- Option to sort tags by name in `--totals`

### 1.0.33

#### FIXED

- Gem dependency updates

### 1.0.30

#### FIXED

- Fix for array comparison error

### 1.0.29

#### FIXED

- Bugfixes

### 1.0.28

#### IMPROVED

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

#### IMPROVED

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

#### IMPROVED

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

#### IMPROVED

#### IMPROVED

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

#### IMPROVED

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

#### IMPROVED

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

#### IMPROVED

- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

#### FIXED

- Fix handling of "local" config files, allowing per-project configurations

### 1.0.21

#### NEW

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)

#### FIXED

- CSS fix

### 1.0.20

#### NEW

- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

#### IMPROVED

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS

### 1.0.19

#### IMPROVED

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

#### IMPROVED

- Loosened up the template color resetting a bit more

#### FIXED

- Fix `undefined method [] for nil class` error in `doing view`

### 1.0.17

#### NEW

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

#### FIXED

- Fixes overzealous color resetting

### 1.0.15

#### FIXED

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

#### IMPROVED

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

#### FIXED

- Fix gsub error in doing meanwhile

### 1.0.8pre

#### NEW

- added doing on command
- Added autotagging to tag command
- JSON output option to view commands
- date filtering, improved date language
- let view templates define output format (csv, json, html, template)

#### IMPROVED

- add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

#### IMPROVED

- Slightly fuzzier searching in the grep command
- cleaner exits, `only_timed` key for view configs
- making the note command append new notes better, and load existing notes in the editor if `-e` is called
- handle multiple tag input in `show` tag filter
- Global tag operations, better reporting

#### FIXED

- fix for `-v` option

### 1.0.4pre

#### IMPROVED

- Improved HTML output
- `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
- add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
- fix for 1.8.7 `Dir.home` issue
- version bump
- don't show tag totals with zero times
- zsh completion for doing
- HTML styling
- `--only_timed` option
- added zsh completion file to `README.md`
- add zsh completion file

### 1.0.3pre

#### IMPROVED

- `done` command: making `--took` modify start time if `--back` isn't specified
- Cleaned up time totals, improved HTML output
- fixes for `--back` and `--took` parsing
- Adding more complete terminal reporting to archive command

### 1.0.0pre

#### IMPROVED

- Skipped ahead in the version numbering. Because I don't care.
- Added a `note` command and `--note` flags for entry creation commands

### 0.2.6pre

#### IMPROVED

- `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
- Add tests for Darwin to hide OS X-only features on other systems
- `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
- `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
- Basic command line reporting
- `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
- `doing grep` for searching by text or regex

### 0.2.5

#### IMPROVED

- Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
- Add section label to archived tasks automatically, excepting `Currently` section
- Today outputs and backdate for finish
- HTML styling and fix for 1.8.7 HAML errors
- Look, HTML output! (`--output html`)
- Also, `--output csv`
- let doing `archive` function on all sections
- option to exclude date from _@done_,  
- output newlines in sections and views
- Flagging (`doing mark`)
- fix for view/section guess error
- Adding tag filtering to archive command (`doing archive \@done`)
- `doing yesterday`
- `doing done -r` to remove last doing tag (optionally from `-s Section`)
- Add `-f` flag to specify alternate doing file
- `meanwhile` command

### 0.2.1

#### IMPROVED

- CSV output for show command (`--csv`)
- HTML output for show command (`--output html`)
- fuzzy searching for all commands that specify a view. 
- In the terminal, you'll see "Assume you meant XXX" to show what match it found, but this is output to STDERR (and won't show up if you're redirecting the output or using it in GeekTool, etc.)
- `tags_color` in view config to highlight tags at the end of the lines. Can be set to any of the `%colors`.
- Basic time tracking. 
- `-t` on `show` and `view` will turn on time calculations
- Intervals between timestamps and dated _@done_ tags are calculated for each line, if the tag exists. 
- You must include a `%interval` token in the appropriate template for it to show
- _@start(date)_ tags can optionally be used to override the timestamp in the calculation
- Any other tags in the line have that line's total added to them
- Totals for tags can be displayed at the end of output with `--totals`


### 0.2.0

#### IMPROVED

- `doing done` without argument tags last entry done
- `-a` archives them
- `doing finish` or `doing finish X` marks last X entries done
- `-a` archives them
- `doing tag tag1 [tag2]` tags last entry or `-c X` entries
- `doing tag -r tag1 [tag2]` removes said tag(s)
- custom views additions
- custom views can include `tags` and `tags_bool`
- `tags` is a space-separated list of tags to filter the results by
- `tags_bool` defines `AND` (all tags must exist), `OR` (any tag exists), or `NONE` (none of the tags exist)
- `order` key (`asc` or `desc`) defines output sort order by date
- section key can be set to `All` to combine sections
- `doing show` updates
- accepts `all` as a section
- arguments following section name are tags to filter by
- `-b` sets boolean (`AND`, `OR`, `NONE`) or (`ALL`, `ANY`, `NONE`) (default `OR`/`ANY`)
- use `-c X` to limit results
- use `-s` to set sort order (`asc` or `desc`)
- use `-a` to set age (`newest` or `oldest`)
- fuzzy section guessing when specified section isn't found
- fuzzy view guessing for `doing view` command

### 0.1.9

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later` and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)
- `doing views` shows all available custom views
- `doing view` without a view name will let you choose a view from a menu
- `doing archive` fixed so that `-k X` works to keep `X` number of entries in the section

### 0.1.7

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)

doing### 2.1.30

2022-02-16 07:18

#### IMPROVED

- `doing changes` does a better job of parsing a lookup string like '>= 2.1.10 < 2.1.15'

#### FIXED

- System agnostic platform detection, so commands that check for Darwin won't error out on other systems
- `doing completions` debugging code

### 2.1.29

2022-02-14 12:42

#### IMPROVED

- `doing changes --interactive` will load up a changelog viewer using fzf. Because it makes me happy, that's why.

### 2.1.28

2022-02-14 11:39

#### FIXED

- Lines merging in `doing changes --changes` output

### 2.1.27

2022-02-14 06:04

#### NEW

- `doing finish --update` will overwrite any existing @done tag with a new date (current time or set with `--at` or `--back`)

#### IMPROVED

- Code refactoring and cleanup
- Include release dates in `doing changes` output when available
- Allow various naming conventions for %color strings in templates. Now `boldwhite`, `brightwhite`, `bg_bold_cyan`, and `bold_bg_cyan` all work (for example)
- Common flags (e.g. --search, --tag) found on multiple commands consolidated and help descriptions matched
- `commands_accepting` now accepts multiple arguments and a `--bool` flag
- `changes` command can now output changes only (no version numbers) and defaults to raw Markdown if not a TTY or the `--md` flag is used
- `doing archive` now accepts `--after` and `--from` date filters

#### FIXED

- Some flag descriptions in help
- Editor detection

### 2.1.26

2022-01-23 16:14

#### NEW

- Use plugins.hidden_commands in configuration to disable any command (array of command names). Note that some commands use aliases and the first name should be used.
- `doing commands [add|remove]` allows interactive enabling and disabling of default and custom commands

#### IMPROVED

- Moved all commands into separate files for management

#### FIXED

- Changelog command regex too greedy when parsing changelog

### 2.1.25

2022-01-23 09:25

### 2.1.24

2022-01-22 17:27

#### IMPROVED

- Minor update to Fish completion script

#### FIXED

- Changelog formatting issue

### 2.1.23

2022-01-22 15:52

#### NEW

- All display commands (except view) now accept `--config_template TEMPLATE_KEY` to override that commands default template.
- Display commands accept `--template`, which takes a template string containing %placeholders and overrides the commands default template output. Affects grep, last, on, recent, show, since, today, yesterday

#### IMPROVED

- With complete examples in the help output for most commands, `doing help` almost always requires scrolling up. It now automatically paginates using your system $PAGER (or best detected option).
- `doing tags` takes a MAX_COUNT argument to limit results when searching
- `doing tags --line` flag to output tags in a single line
- Mostly for my own use, `doing changes` (which views the changelog) now accepts `--lookup VERSION` and `--search SEARCH_PATTERN`
- `doing changes --lookup` accepts `"< 2.1 > 2.0"`, `"2.1.10-2.2"`, a specific version, or a version number with wildcards
- When registering hooks, you can pass an array to register a block for multiple events, assuming the events provide the same block arguments (like post_entry_added and post_entry_updated)

#### FIXED

- Running `--tag "@doing"` wouldn't work where `--tag "doing"` would. Now properly ignoring @ symbols

### 2.1.22

2022-01-21 14:53

### 2.1.21

2022-01-20 12:05

#### FIXED

- Custom types not available to custom commands

### 2.1.20

2022-01-20 11:49

#### NEW

- Autotag option for interactive `doing select` menu
- (Breaking change) Made the later command an optional plugin, see wiki for how to install (and create) custom commands
- Config setting doing_file_sort (asc or desc) determines the sort order of entries in the actual Doing file. Has no effect on other operations, just allows you to store the file with newest entries at top (desc) or bottom (asc).

#### IMPROVED

- Autotag improvements
- If doing is run without a command but with arguments, execute it as if you'd run `doing now`, passing the arguments to that. So you can just write "doing this thing" instead of "doing now this thing", as long as the first word of the arguments is not a recognized command.

#### FIXED

- `doing again` should only mark the original repeating entry @done, not search for the last unfinished entry
- Error when using `doing finish --auto`
- `doing on wed` when today is wednesday not returning results
- Using `config set` with a false value deleted the key from config
- `config set` with true or false value was inserting a quoted string
- Entries were not being sorted (at all) within sections when writing the Doing file

### 2.1.19

2022-01-18 08:40

#### FIXED

- Search highlighting error with some pattern searches
- Reverse sort of items in menu from `--interactive` flags
- Nil error when `--interactive` was called without search results

### 2.1.18

Build automation test

### 2.1.17

2022-01-18 07:26

#### NEW

- `--hilite` option for `doing search` to highlight matches in search results (terminal output only)
- `--hilite` flag for `show` and `view` to highlight results when used with `--search`

#### IMPROVED

- Show preview of up to 5 items when confirming a delete operation so you actually know what you're deleting
- Allow `--ask` when creating new entry via STDIN pipe
- Tab completion for known tags when creating an entry interactively
- Add purple as an alias for magenta in template colors

#### FIXED

- Clear STDIN before requesting input

### 2.1.16

2022-01-18 02:45

#### NEW

- `doing done --from "3pm to 3:15pm"` to set start and end times with natural language string

#### IMPROVED

- Running `doing tag` without arguments takes command line input
- If `doing now` or `doing later` are run without arguments, interactively request necessary information (you can still use `--editor` to edit in your preferred editor)
- Tab completion for tags when entering at prompt
- Use readline when requesting input text, better editing features
- `doing done --at` no longer overrides `--back`

#### FIXED

- `doing select` -> output formatted empty output
- Sort items by date when using `doing select --editor` (was loading in selection order instead)
- Ruby 2.7 error in template output (.empty? on FalseClass)
- Don't add empty entry when cancelling `--editor`
- Batch editing bugs

### 2.1.15

2022-01-17 07:25

#### NEW

- When completing an entry, if the elapsed time would be greater than a (configurable) amount, doing will now ask for confirmation and allow you to enter a new duration before setting the @done date

#### IMPROVED

- When entering intervals, you can now use 1h30m in addition to 1.5h or 90m
- Date expansion works in more circumstances
- You can include date tags with natural language values when adding tags via `doing select`

#### FIXED

- Tags containing values with spaces no longer cause errors

### 2.1.14

#### NEW

- All commands that accept `--note` now accept `--ask`, which requests input via readline after creating the note. Multiple lines are allowed, hit return twice to end editing. Works alongside `--note` and `--editor`

#### IMPROVED

- Implement `--search` and `--from` filtering for import plugins
- UTC format date strings in select menus for consistency (was relative date formatting)
- Don't populate the fzf search with `--search`, it's already filtered. Separated `--query` from `--search` if you do want to populate the query string in addition to `--search` filtering
- When showing relative dates, don't include the year if the date is the previous year but a later month than the current month (less than a year old)
- When using `--editor` while adding an entry, include any note specified on the command line or via `--ask` for further editing

### 2.1.13

#### NEW

- `--val` flag for all display commands, allows tag value queries. Tag values are contained in parenthesis after the tag, e.g. @progress(50). Queries look like `--val "done < two weeks ago"`, "project *= oracle" or "progress >= 50". Wildcards allowed in value, comparators can be <, >, <=, >=, ==, *= (contains), ^= (begins with), $= (ends with). Numeric and date comparisons are detected automatically. Text comparisons are case insensitive. `--val` can be used multiple times in a command and you can use `--bool` to specify AND, OR, or NOT (default AND)
- `doing tag` now accepts a `--value` flag to define a value for a single tag, e.g. @tag(value)

#### FIXED

- `doing last --editor` errors

### 2.1.12

#### NEW

- Tag_dir command creates/updates .doingrc files in the current directory with default_tags values. Then all entries created within that directory (or subdirs) get tagged with that value.
- Synonym triggers allow `*` and `?` wildcards
- Add `--delete` flag for `doing last` to delete last entry
- `--delete` and `--editor` flags for `doing search`, batch edit and delete
- Example hook to add new entries containing a certain tag to Day One
- New hooks: pre_entry_add, post_entry_added, post_entry_updated, post_entry_removed, pre_export

#### IMPROVED

- If you need to use a colon in an autotag transform pattern, you can split with double colon, e.g. pattern::replacement
- Arrays defined in local configurations merge with main config instead of overwriting

#### FIXED

- `doing tags --interactive` wasn't showing menu

### 2.1.10

#### NEW

- `--age` (oldest|newest) option for view command

### 2.1.9

#### IMPROVED

- Only attempt to install fzf if it doesn't exist on the system. In case of errors, this means a user can manually install fzf and still be able to access `--interactive` options

#### FIXED

- Rotate command only archiving half of requested items
- Frozen string error in doing import plugin

### 2.1.8

#### NEW

- Hidden command `doing commands_accepting` which shows all commands that accept a given option, e.g. `doing commands_accepting search` shows all commands that take a search filter
- Hidden command `doing changelog` which outputs a paginated, formatted version of the change history.

#### IMPROVED

- The output of `doing template --list` now shows the file type of each template
- Output templates can now be saved to a default location/filename using `doing template html --save`

#### FIXED

- Error running `doing recent` on certain older ruby versions

### 2.1.6

#### NEW

- `doing redo` undoes a redo
- `doing undo -i` offers a list of available versions for selection
- Multiple undo. Every time a command modifies the doing file, a backup is written. Running `doing undo` repeatedly steps back through history, `doing undo 5` jumps back 5 versions
- When resetting via `doing select`, prompt for a date string
- `doing reset` accepts a date string argument to use as start date instead of current time if provided
- `doing tags` lists tags used in any/all sections, sortable, with or without frequency counts
- `doing show --menu` offers an interactive menu for selecting section and tag filters
- All commands that accept a `--tag` filter can now handle wildcards in the tag names. * to match any number of characters, ? to match a single character.
- New boolean type for tag searches, PATTERN (which is now the default). Combine tags using symbols to create more complex boolean searches, e.g. "doing +coding -work"
- You can now define `date_tags` in config, an array of tags/patterns that will be recognized when parsing for natural language dates which are converted when saving new entries
- `--search` strings can contain quoted phrases and use +/- to require or ban terms, e.g. `--search 'doing +coding -writing'
- Interactive option for redo command
- Plugins for Day One export

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump
- Matching algorithm can be configured in settings
- All template placeholders can now use the "printf" formatting that %title and %note have, allowing for padding, prefixes, etc.
- Move default locations for doing file and backups to ~/.local/share/doing
- `doing show --menu` will only offer tags that exist after any tag/search filters have been run
- `doing show @tag` with `--menu` will first filter by the @tag, then do an OR search for tags selected from the menu

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed
- Preserve colors when wrapping text to new lines
- Tag highlighting errors
- Template options specified in views were being overriden by options in templates. View config now has precedence, but will fall back to template config for missing keys

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed

### 2.1.3

#### NEW

- BREAKING CHANGE: custom classes for Section (hash) and Items (Array). @content is still a regular Hash. Sections have methods :original and :items. This will affect plugins as wwid.content[section][:items] is now wwid[section].items (same for :original)
- `doing config set -r key.path` will delete a key from any config file, removing empty parent keys
- `config list` will list detected .doingrc files and the main config file in order of precedence - refactoring
- When modifying start dates or @done dates via an editor command, natural language strings can be used and will be parsed into doing-formatted dates automatically
- When editor is invoked, entry titles include start date, which can be modified
- `--before`, `--after`, and `--from` date filters for select command
- `--from` flag for `doing today` and `doing yesterday`, filter by time range
- `--from` flag for `doing search`, filter by date/time range
- Commands that accept `--before`, `--after`, and `--from` can now filter on time ranges. If the date string given contains only a time (no day or date), it will be interpreted as a time range, meaning the date isn't filtered, but only entries within the time range are shown/processed
- Add %duration placeholder to template variables
- Add `interval_format` setting to config (applies to root or any view/template) to set intervals/durations to human (2h 15m) or text (00:02:15)
- Add `duration` key to config (root or view/template). If set to true, will display durations by default (no need for `--duration`)
- Most display commands now have a `--duration` flag that will display an elapsed time if the entry is not marked @done

#### IMPROVED

- Config -o raw outputs value as YAML if result is a Hash/mapping, unquoted string if a single value, comma-separated list if it's an Array.
- Config -o json no longer includes key, only value.
- System agnostic method for checking available executables (pager, editor)
- Using `config set` and selecting a local config will no longer write the entire config to the local .doingrc. Instead, a nested path to the particular setting will be added to the config file.
- Config set will create missing keys. Fuzzy matching will work until the path fails, then path elements after that point will be added as verbatim keys to the specified configuration (with confirmation)
- Make menus only as tall as needed, so 5 options don't take up the whole screen
- Better word wrap for long note lines

#### FIXED

- `finish --took 60m` is supposed to backdate the start date if needed to finish at the current time and maintain an elapsed time
- If an editor was specified for config (or default as fallback) with command line options (e.g. `emacs -nw`), Doing would fail to recognize that the executable was available.

### 2.0.25

#### NEW

- `doing config set` to set single config values from command line
- BREAKING CHANGE: Moves ~/.doingrc to ~/.config/doing/config.yml
- BREAKING CHANGE: convert config flags to subcommands, e.g. `doing config --udpate` => `doing config update`, and `doing config --dump` => `doing config dump`

### 2.0.24

- include fzf source directly, in case git isn't installed
- fall back to installing fzf with sudo on error

### 2.0.20

#### IMPROVED

- completion script generator refactor and progress bars

#### FIXED

- compile fzf for current operating system

### 2.0.19

#### FIXED

- Remove any coloring before writing to doing file

### 2.0.18

#### FIXED

- Escape codes being included in doing file

### 2.0.17

#### IMPROVED

- Improvements to %title formatting and wrapping

### 2.0.16

- Test release to validate git flow automation

### 2.0.13

#### FIXED

- Remove amatch gem dependency due to compatibility issues with Windows systems (also removes `--fuzzy` option from all search commands)

### 2.0.11

#### NEW

- Append `/r` to tag transforms to replace original tag

#### FIXED

- Autotag tag transform fixes

### 2.0.10

#### NEW

- Add 'timer_format' config with 'human' option for tag totals
- If `doing view` and `doing show` are confused, offer option to run the other command
- `doing completion` to generate shell completion scripts for zsh, bash, and fish
- `--search` and `--not` for cancel command
- `--case` flag for commands with `--search`. Can be (c)ase-sensitive, (i)nsensitive, or (s)mart (default smart, case insensitive unless search string contains uppercase letters)
- Add `--exact` flag to all commands with `--search` flag to force exact matching without requiring single quote prefix
- Add `--not` flag to all commands with filters (`--tag`, `--search`, `--before`, etc.) to negate the filter and return entries NOT matched

#### IMPROVED

- More command line feedback
- Error formatting and output
- Add subcommand completion for `doing help` in fish shell
- Logging and error handling

#### FIXED

- Zsh completion not outputting results
- Remove `--[no]` from non-negatable options
- `doing plugins -t export -c` not outputting columns
- View config not respecting tag_order setting
 
### 2.0.3.pre

#### NEW

- Import calendar events from Calendar.app on macOS
- `doing config --update` will add newly added config keys to your existing config file (handy with plugins that define their own config keys)
- Add %idnote template placeholder for "indented note" (entire note indented one tab)
- (loosely printf-esque) formatting options for `%note` template placeholder
- `--interactive` mode to act on results of `doing grep`
- Printf formatting for title and date
- Doing import plugin
- Plugins command to list plugins
- `--dump` option for `doing config` to output a key.path config key as JSON, YAML, or raw output
- `--no-color` global flag
- Log levels, with `--quiet` and `--verbose` global flags
- Convert CLI messaging to Logger-based system
- Use DOING_DEBUG, DOING_QUIET, or DOING_LOG_LEVEL environment variables to specify log levels before configuration is read
- Hooks, register plugins to run based on events
- --[no-]pager and paginate: config option to enable paging output
- Never_finish and never_time config options to prevent items matching tags/sections from ever receiving @done (never_finish) or @done timestamp (never_time) - More configuration refactoring

#### IMPROVED

- Timeline output formatting
- Major plugin architecture refactoring
- Fix regression where notes stored in doing file were outdented, breaking TaskPaper compatibility
- When accepting a date filter, allow end date to be in the future
- If an edited item has no changes, don't update/output notification - Don't start with query when using grep `--interactive`
- Select menu item formatting
- Output wrapping for terminal display
- Redirect warn to STDOUT when run with `--stdout`
- Fish autocomplete
- `--config_file` global flag deprected, now uses $DOING_CONFIG environment variable so that config overrides can be available before the initial configuration is run
- When `--stdout` or not a TTY, no color or output formatting
- Highlight tags when showing results. Because it looks nice.
- `--tag` and `--search` for `doing note`
- View/section fuzzy guessing
- Error reporting
- If `doing config` finds local doingrc files, offers a menu for editing
- More filtering options for `doing finish`
- Doing done accepts `--unfinished` flag to finish last entry not marked @done (instead of last entry)
- Doing done accepts `--note` flag to append a note when completing an entry

#### FIXED

- Multi-word unquoted arguments to add_section being truncated
- Show `--from` with date span
- Handling of arbitrary times in natural language dates
- Backward scope of since command with arbitrary times
- `doing rotate --keep` wasn't respecting keep value

### 1.0.93

#### FIXED

- Gemfile error

### 1.0.91

#### NEW

- "taskpaper" format available for all output options
- "markdown" format available for all output commands (GFM-style task list, customizable template)
- `--rename` option for tag command to replace tags
- `--regex` option for tag command, for `--remove` and `--rename`

### 1.0.90

#### IMPROVED

- doing finish `--auto` now pulls from all sections, not just the section of the target entry

#### FIXED

- Minor fix for shell command in doing select
- Fix for doing finish `--auto` when matched item is last in list

### 1.0.89

#### NEW

- Pretty print JSON output
- `--no-menu` option for select command to use `--query` as a filter and act on matching entries without displaying menu

### 1.0.88

#### IMPROVED

- Add `--before` and `--after` time search to yesterday command
- Add `--before` and `--after` date search to search/grep command
- Add `--tag_order` to yesterday command

### 1.0.87

#### IMPROVED

- Add leading spaces to make %shortdate align properly, at least for the last week
- Add `--tag`, `--bool`, and `--search` to view command
- Add `--before` and `--after` date search to view command
- Add `--before` and `--after` date search to show command
- Add `--before` and `--after` time search to today command
- Add `--search` filter to show command
- More alignment/formatting fixes for %shortdate

### 1.0.86

#### IMPROVED

- Add `count` config option for templates->recent

### 1.0.85

#### IMPROVED

- Add `--before` DATE_STRING to archive and rotate commands
- Only create on rotate file per day, merge new entries into existing file

#### FIXED

- Fix `--auto` for finish command

### 1.0.84

#### NEW

- `rotate` command for archiving entries to new file

#### FIXED

- Fixed current_section config key not being honored in some commands

### 1.0.83

#### FIXED

- Fixes for `doing view` options, additional config keys for views

### 1.0.82

#### FIXED

- Bugfixes

### 1.0.81

#### IMPROVED

- fzf menu improvements
- allow multiple selections `doing select` action menu

### 1.0.80

#### IMPROVED

- Convert all menus to fzf screens

### 1.0.79

#### IMPROVED

- Wildcard tag removal using `doing select -t "tag*" -r`
- fzf menu display polish

#### FIXED

#### FIXED

- Gem missing fzf

### 1.0.78

#### IMPROVED

- If no action is specified with select command, an interactive menu is
presented
- add output action select command with formatting and save options
- Don't link URLs in html output that don't have a protocol

### 1.0.76

#### IMPROVED

- Refine editing multiple selections (doing select)

### 1.0.74

#### NEW

- Add `--tag` and `--search` flags to tag command to tag all entries matching search terms
- Add since command, which is the same as `doing on tuesday to now` but `doing since tuesday` just feels more intuitive. 

### 1.0.73

#### FIXED

- Fix for timeline output

### 1.0.72

#### NEW

- Add `doing select` to show menu of all tasks, searchable with fuzzy matching and the ability to perform certain tasks on multiple selections.

### 1.0.71

#### FIXED

- Fix for template command not working at all

### 1.0.70

#### FIXED

- Fix for `doing done --took 30m` setting the wrong @done timestamp when completing previous item

### 1.0.69

#### IMPROVED

- Add `--unfinished` option to finish and cancel commands

### 1.0.68

#### FIXED

- Fix error in `doing show --sort` argument parsing

### 1.0.67

#### FIXED

- Gem packaging error

### 1.0.66

#### IMPROVED

- More flexible boolean specification, can be: all, and, any, or, not, or none

#### FIXED

- Fix for some long flags being interpreted as arrays instead of strings
- Fix for archive command not removing original entries from archived section

### 1.0.65

#### IMPROVED

- Prevent duplicates/overlapping entries when importing

### 1.0.64

#### NEW

- Initial import feature for Timing.app reports

### 1.0.63

#### IMPROVED

- If `doing done --took=X` results in completion date greater than current time, use current time as completion date and backdate the entry's timestamp to fit

### 1.0.62

#### FIXED

- `doing done` with `--took=` and without `--back=` should set end time to start date plus `--took` value

### 1.0.61

#### IMPROVED

- Add `--search` filter to `doing archive`

### 1.0.60

#### FIXED

- Default value for `doing again --bool` was ALL, should be AND

### 1.0.59

#### IMPROVED

- Improvements to `doing again --tag=` functionality

### 1.0.58

#### IMPROVED

- Finish previous task if `doing again` and not already completed

### 1.0.57

#### IMPROVED

- Unit tests

### 1.0.56

#### IMPROVED

- Tag command tests

#### FIXED

- Doing not reading per-directory .doingrc configs

### 1.0.55

#### NEW

- Added config_editor_app setting to config so you can have
- A parenthetical at the end of an entry title becomes an attached
- `--editor` flag for `doing last` to edit last entry
- `--tag=` flag to filter `doing last` by tag
- `--search=` to filter `doing last` by text/regex search
- `--search=` for `doing finish`, finish last X entries matching search
- Add `tags_color` as a primary config key to highlight @tags in displayed entries

#### IMPROVED

- Clean up command line help
- `--editor` improvements for all commands that use it

#### FIXED

- Doing finish `--took` throwing error
- Doing tag `--remove` was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date

#### IMPROVED

- Add `--no-color` option to view command
- Add `--tag` to show for compatibility

#### FIXED

- Error running finish without `--tag` flag
- `--archive` flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry

#### FIXED

- `--archive` flag on finish, done, and cancel causing error

### 1.0.49

#### FIXED

- Fix for missing date on @done tags

### 1.0.48

#### FIXED

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

#### IMPROVED

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

#### IMPROVED

- Code cleanup

### 1.0.45

#### IMPROVED

- Only execute run_after script if changes are written

### 1.0.44

#### IMPROVED

- Remove unnecessary console logging

### 1.0.43

#### NEW

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

#### FIXED

- Fix note indentation in doing file

### 1.0.41

#### FIXED

- Fix for repeated backreferences in tag transform

### 1.0.40

#### IMPROVED

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

#### NEW

- Tag transforms
- Option to sort tags by name in `--totals`

### 1.0.33

#### FIXED

- Gem dependency updates

### 1.0.30

#### FIXED

- Fix for array comparison error

### 1.0.29

#### FIXED

- Bugfixes

### 1.0.28

#### IMPROVED

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

#### IMPROVED

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

#### IMPROVED

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

#### IMPROVED

#### IMPROVED

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

#### IMPROVED

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

#### IMPROVED

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

#### IMPROVED

- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

#### FIXED

- Fix handling of "local" config files, allowing per-project configurations

### 1.0.21

#### NEW

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)

#### FIXED

- CSS fix

### 1.0.20

#### NEW

- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

#### IMPROVED

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS

### 1.0.19

#### IMPROVED

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

#### IMPROVED

- Loosened up the template color resetting a bit more

#### FIXED

- Fix `undefined method [] for nil class` error in `doing view`

### 1.0.17

#### NEW

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

#### FIXED

- Fixes overzealous color resetting

### 1.0.15

#### FIXED

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

#### IMPROVED

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

#### FIXED

- Fix gsub error in doing meanwhile

### 1.0.8pre

#### NEW

- added doing on command
- Added autotagging to tag command
- JSON output option to view commands
- date filtering, improved date language
- let view templates define output format (csv, json, html, template)

#### IMPROVED

- add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

#### IMPROVED

- Slightly fuzzier searching in the grep command
- cleaner exits, `only_timed` key for view configs
- making the note command append new notes better, and load existing notes in the editor if `-e` is called
- handle multiple tag input in `show` tag filter
- Global tag operations, better reporting

#### FIXED

- fix for `-v` option

### 1.0.4pre

#### IMPROVED

- Improved HTML output
- `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
- add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
- fix for 1.8.7 `Dir.home` issue
- version bump
- don't show tag totals with zero times
- zsh completion for doing
- HTML styling
- `--only_timed` option
- added zsh completion file to `README.md`
- add zsh completion file

### 1.0.3pre

#### IMPROVED

- `done` command: making `--took` modify start time if `--back` isn't specified
- Cleaned up time totals, improved HTML output
- fixes for `--back` and `--took` parsing
- Adding more complete terminal reporting to archive command

### 1.0.0pre

#### IMPROVED

- Skipped ahead in the version numbering. Because I don't care.
- Added a `note` command and `--note` flags for entry creation commands

### 0.2.6pre

#### IMPROVED

- `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
- Add tests for Darwin to hide OS X-only features on other systems
- `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
- `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
- Basic command line reporting
- `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
- `doing grep` for searching by text or regex

### 0.2.5

#### IMPROVED

- Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
- Add section label to archived tasks automatically, excepting `Currently` section
- Today outputs and backdate for finish
- HTML styling and fix for 1.8.7 HAML errors
- Look, HTML output! (`--output html`)
- Also, `--output csv`
- let doing `archive` function on all sections
- option to exclude date from _@done_,  
- output newlines in sections and views
- Flagging (`doing mark`)
- fix for view/section guess error
- Adding tag filtering to archive command (`doing archive \@done`)
- `doing yesterday`
- `doing done -r` to remove last doing tag (optionally from `-s Section`)
- Add `-f` flag to specify alternate doing file
- `meanwhile` command

### 0.2.1

#### IMPROVED

- CSV output for show command (`--csv`)
- HTML output for show command (`--output html`)
- fuzzy searching for all commands that specify a view. 
- In the terminal, you'll see "Assume you meant XXX" to show what match it found, but this is output to STDERR (and won't show up if you're redirecting the output or using it in GeekTool, etc.)
- `tags_color` in view config to highlight tags at the end of the lines. Can be set to any of the `%colors`.
- Basic time tracking. 
- `-t` on `show` and `view` will turn on time calculations
- Intervals between timestamps and dated _@done_ tags are calculated for each line, if the tag exists. 
- You must include a `%interval` token in the appropriate template for it to show
- _@start(date)_ tags can optionally be used to override the timestamp in the calculation
- Any other tags in the line have that line's total added to them
- Totals for tags can be displayed at the end of output with `--totals`


### 0.2.0

#### IMPROVED

- `doing done` without argument tags last entry done
- `-a` archives them
- `doing finish` or `doing finish X` marks last X entries done
- `-a` archives them
- `doing tag tag1 [tag2]` tags last entry or `-c X` entries
- `doing tag -r tag1 [tag2]` removes said tag(s)
- custom views additions
- custom views can include `tags` and `tags_bool`
- `tags` is a space-separated list of tags to filter the results by
- `tags_bool` defines `AND` (all tags must exist), `OR` (any tag exists), or `NONE` (none of the tags exist)
- `order` key (`asc` or `desc`) defines output sort order by date
- section key can be set to `All` to combine sections
- `doing show` updates
- accepts `all` as a section
- arguments following section name are tags to filter by
- `-b` sets boolean (`AND`, `OR`, `NONE`) or (`ALL`, `ANY`, `NONE`) (default `OR`/`ANY`)
- use `-c X` to limit results
- use `-s` to set sort order (`asc` or `desc`)
- use `-a` to set age (`newest` or `oldest`)
- fuzzy section guessing when specified section isn't found
- fuzzy view guessing for `doing view` command

### 0.1.9

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later` and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)
- `doing views` shows all available custom views
- `doing view` without a view name will let you choose a view from a menu
- `doing archive` fixed so that `-k X` works to keep `X` number of entries in the section

### 0.1.7

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)

 and hitting tab will offer completions of subcommands and their options.'  command :completion do |c|
- `doing completion install SHELL` will copy the default completion scripts to your ~/.local/share/doing folder and offer to symlink them to autoload directories. These scripts are generated with each release but will not include any custom commands or plugins in the completions.

#### IMPROVED

- `doing completion` now uses subcommands, `generate` and `install`. The install command will write default scripts to ~/.local/share/doing/completion and link them into the appropriate autoload directory for the shell. The generate command will create new scripts that include any custom commands and plugins. # Please enter the commit message for your changes. Lines starting # with '#' will be ignored, and an empty message aborts the commit. # # On branch develop # Your branch is ahead of 'origin/develop' by 1 commit. # # Changes to be committed: #	modified:   CHANGELOG.md #	modified:   bin/commands/completion.rb #	modified:   lib/doing/completion.rb # # ------------------------ >8 ------------------------ # Do not modify or remove the line above. # Everything below it will be ignored. diff --git a/CHANGELOG.md b/CHANGELOG.md index 9dbe52b..d4321f8 100644 --- a/CHANGELOG.md +++ b/CHANGELOG.md @@ -1,3 +1,15 @@ +### 2.1.31 + +2022-02-16 10:13 + +#### NEW + +- `doing completion install SHELL` will copy the default completion scripts to your ~/.local/share/doing folder and offer to symlink them to autoload directories. These scripts are generated with each release but will not include any custom commands or plugins in the completions. # Please enter the commit message for your changes. Lines starting # with '#' will be ignored, and an empty message aborts the commit. # # On branch develop # Your branch is up to date with 'origin/develop'. # # Changes to be committed: #	modified:   Gemfile.lock #	modified:   README.md #	modified:   bin/commands/completion.rb #	modified:   lib/doing/completion.rb #	modified:   lib/doing/version.rb # # ------------------------ >8 ------------------------ # Do not modify or remove the line above. # Everything below it will be ignored. diff --git a/Gemfile.lock b/Gemfile.lock index c780406..9261a44 100644 --- a/Gemfile.lock +++ b/Gemfile.lock @@ -1,7 +1,7 @@  PATH    remote: .    specs: + +#### IMPROVED + +- When generating completion scripts using `doing completion --file FILE_PATH`, if the file specified is not in an auto-load directory for the shell type, offer to symlink the output to an appropriate directory +  ### 2.1.30    2022-02-16 07:18 diff --git a/bin/commands/completion.rb b/bin/commands/completion.rb index 3d4f479..c3358e5 100644 --- a/bin/commands/completion.rb +++ b/bin/commands/completion.rb @@ -5,36 +5,65 @@ desc 'Generate shell completion scripts'  long_desc 'Generates the necessary scripts to add command line completion to various shells,  so typing ### 2.1.30

2022-02-16 07:18

#### IMPROVED

- `doing changes` does a better job of parsing a lookup string like '>= 2.1.10 < 2.1.15'

#### FIXED

- System agnostic platform detection, so commands that check for Darwin won't error out on other systems
- `doing completions` debugging code

### 2.1.29

2022-02-14 12:42

#### IMPROVED

- `doing changes --interactive` will load up a changelog viewer using fzf. Because it makes me happy, that's why.

### 2.1.28

2022-02-14 11:39

#### FIXED

- Lines merging in `doing changes --changes` output

### 2.1.27

2022-02-14 06:04

#### NEW

- `doing finish --update` will overwrite any existing @done tag with a new date (current time or set with `--at` or `--back`)

#### IMPROVED

- Code refactoring and cleanup
- Include release dates in `doing changes` output when available
- Allow various naming conventions for %color strings in templates. Now `boldwhite`, `brightwhite`, `bg_bold_cyan`, and `bold_bg_cyan` all work (for example)
- Common flags (e.g. --search, --tag) found on multiple commands consolidated and help descriptions matched
- `commands_accepting` now accepts multiple arguments and a `--bool` flag
- `changes` command can now output changes only (no version numbers) and defaults to raw Markdown if not a TTY or the `--md` flag is used
- `doing archive` now accepts `--after` and `--from` date filters

#### FIXED

- Some flag descriptions in help
- Editor detection

### 2.1.26

2022-01-23 16:14

#### NEW

- Use plugins.hidden_commands in configuration to disable any command (array of command names). Note that some commands use aliases and the first name should be used.
- `doing commands [add|remove]` allows interactive enabling and disabling of default and custom commands

#### IMPROVED

- Moved all commands into separate files for management

#### FIXED

- Changelog command regex too greedy when parsing changelog

### 2.1.25

2022-01-23 09:25

### 2.1.24

2022-01-22 17:27

#### IMPROVED

- Minor update to Fish completion script

#### FIXED

- Changelog formatting issue

### 2.1.23

2022-01-22 15:52

#### NEW

- All display commands (except view) now accept `--config_template TEMPLATE_KEY` to override that commands default template.
- Display commands accept `--template`, which takes a template string containing %placeholders and overrides the commands default template output. Affects grep, last, on, recent, show, since, today, yesterday

#### IMPROVED

- With complete examples in the help output for most commands, `doing help` almost always requires scrolling up. It now automatically paginates using your system $PAGER (or best detected option).
- `doing tags` takes a MAX_COUNT argument to limit results when searching
- `doing tags --line` flag to output tags in a single line
- Mostly for my own use, `doing changes` (which views the changelog) now accepts `--lookup VERSION` and `--search SEARCH_PATTERN`
- `doing changes --lookup` accepts `"< 2.1 > 2.0"`, `"2.1.10-2.2"`, a specific version, or a version number with wildcards
- When registering hooks, you can pass an array to register a block for multiple events, assuming the events provide the same block arguments (like post_entry_added and post_entry_updated)

#### FIXED

- Running `--tag "@doing"` wouldn't work where `--tag "doing"` would. Now properly ignoring @ symbols

### 2.1.22

2022-01-21 14:53

### 2.1.21

2022-01-20 12:05

#### FIXED

- Custom types not available to custom commands

### 2.1.20

2022-01-20 11:49

#### NEW

- Autotag option for interactive `doing select` menu
- (Breaking change) Made the later command an optional plugin, see wiki for how to install (and create) custom commands
- Config setting doing_file_sort (asc or desc) determines the sort order of entries in the actual Doing file. Has no effect on other operations, just allows you to store the file with newest entries at top (desc) or bottom (asc).

#### IMPROVED

- Autotag improvements
- If doing is run without a command but with arguments, execute it as if you'd run `doing now`, passing the arguments to that. So you can just write "doing this thing" instead of "doing now this thing", as long as the first word of the arguments is not a recognized command.

#### FIXED

- `doing again` should only mark the original repeating entry @done, not search for the last unfinished entry
- Error when using `doing finish --auto`
- `doing on wed` when today is wednesday not returning results
- Using `config set` with a false value deleted the key from config
- `config set` with true or false value was inserting a quoted string
- Entries were not being sorted (at all) within sections when writing the Doing file

### 2.1.19

2022-01-18 08:40

#### FIXED

- Search highlighting error with some pattern searches
- Reverse sort of items in menu from `--interactive` flags
- Nil error when `--interactive` was called without search results

### 2.1.18

Build automation test

### 2.1.17

2022-01-18 07:26

#### NEW

- `--hilite` option for `doing search` to highlight matches in search results (terminal output only)
- `--hilite` flag for `show` and `view` to highlight results when used with `--search`

#### IMPROVED

- Show preview of up to 5 items when confirming a delete operation so you actually know what you're deleting
- Allow `--ask` when creating new entry via STDIN pipe
- Tab completion for known tags when creating an entry interactively
- Add purple as an alias for magenta in template colors

#### FIXED

- Clear STDIN before requesting input

### 2.1.16

2022-01-18 02:45

#### NEW

- `doing done --from "3pm to 3:15pm"` to set start and end times with natural language string

#### IMPROVED

- Running `doing tag` without arguments takes command line input
- If `doing now` or `doing later` are run without arguments, interactively request necessary information (you can still use `--editor` to edit in your preferred editor)
- Tab completion for tags when entering at prompt
- Use readline when requesting input text, better editing features
- `doing done --at` no longer overrides `--back`

#### FIXED

- `doing select` -> output formatted empty output
- Sort items by date when using `doing select --editor` (was loading in selection order instead)
- Ruby 2.7 error in template output (.empty? on FalseClass)
- Don't add empty entry when cancelling `--editor`
- Batch editing bugs

### 2.1.15

2022-01-17 07:25

#### NEW

- When completing an entry, if the elapsed time would be greater than a (configurable) amount, doing will now ask for confirmation and allow you to enter a new duration before setting the @done date

#### IMPROVED

- When entering intervals, you can now use 1h30m in addition to 1.5h or 90m
- Date expansion works in more circumstances
- You can include date tags with natural language values when adding tags via `doing select`

#### FIXED

- Tags containing values with spaces no longer cause errors

### 2.1.14

#### NEW

- All commands that accept `--note` now accept `--ask`, which requests input via readline after creating the note. Multiple lines are allowed, hit return twice to end editing. Works alongside `--note` and `--editor`

#### IMPROVED

- Implement `--search` and `--from` filtering for import plugins
- UTC format date strings in select menus for consistency (was relative date formatting)
- Don't populate the fzf search with `--search`, it's already filtered. Separated `--query` from `--search` if you do want to populate the query string in addition to `--search` filtering
- When showing relative dates, don't include the year if the date is the previous year but a later month than the current month (less than a year old)
- When using `--editor` while adding an entry, include any note specified on the command line or via `--ask` for further editing

### 2.1.13

#### NEW

- `--val` flag for all display commands, allows tag value queries. Tag values are contained in parenthesis after the tag, e.g. @progress(50). Queries look like `--val "done < two weeks ago"`, "project *= oracle" or "progress >= 50". Wildcards allowed in value, comparators can be <, >, <=, >=, ==, *= (contains), ^= (begins with), $= (ends with). Numeric and date comparisons are detected automatically. Text comparisons are case insensitive. `--val` can be used multiple times in a command and you can use `--bool` to specify AND, OR, or NOT (default AND)
- `doing tag` now accepts a `--value` flag to define a value for a single tag, e.g. @tag(value)

#### FIXED

- `doing last --editor` errors

### 2.1.12

#### NEW

- Tag_dir command creates/updates .doingrc files in the current directory with default_tags values. Then all entries created within that directory (or subdirs) get tagged with that value.
- Synonym triggers allow `*` and `?` wildcards
- Add `--delete` flag for `doing last` to delete last entry
- `--delete` and `--editor` flags for `doing search`, batch edit and delete
- Example hook to add new entries containing a certain tag to Day One
- New hooks: pre_entry_add, post_entry_added, post_entry_updated, post_entry_removed, pre_export

#### IMPROVED

- If you need to use a colon in an autotag transform pattern, you can split with double colon, e.g. pattern::replacement
- Arrays defined in local configurations merge with main config instead of overwriting

#### FIXED

- `doing tags --interactive` wasn't showing menu

### 2.1.10

#### NEW

- `--age` (oldest|newest) option for view command

### 2.1.9

#### IMPROVED

- Only attempt to install fzf if it doesn't exist on the system. In case of errors, this means a user can manually install fzf and still be able to access `--interactive` options

#### FIXED

- Rotate command only archiving half of requested items
- Frozen string error in doing import plugin

### 2.1.8

#### NEW

- Hidden command `doing commands_accepting` which shows all commands that accept a given option, e.g. `doing commands_accepting search` shows all commands that take a search filter
- Hidden command `doing changelog` which outputs a paginated, formatted version of the change history.

#### IMPROVED

- The output of `doing template --list` now shows the file type of each template
- Output templates can now be saved to a default location/filename using `doing template html --save`

#### FIXED

- Error running `doing recent` on certain older ruby versions

### 2.1.6

#### NEW

- `doing redo` undoes a redo
- `doing undo -i` offers a list of available versions for selection
- Multiple undo. Every time a command modifies the doing file, a backup is written. Running `doing undo` repeatedly steps back through history, `doing undo 5` jumps back 5 versions
- When resetting via `doing select`, prompt for a date string
- `doing reset` accepts a date string argument to use as start date instead of current time if provided
- `doing tags` lists tags used in any/all sections, sortable, with or without frequency counts
- `doing show --menu` offers an interactive menu for selecting section and tag filters
- All commands that accept a `--tag` filter can now handle wildcards in the tag names. * to match any number of characters, ? to match a single character.
- New boolean type for tag searches, PATTERN (which is now the default). Combine tags using symbols to create more complex boolean searches, e.g. "doing +coding -work"
- You can now define `date_tags` in config, an array of tags/patterns that will be recognized when parsing for natural language dates which are converted when saving new entries
- `--search` strings can contain quoted phrases and use +/- to require or ban terms, e.g. `--search 'doing +coding -writing'
- Interactive option for redo command
- Plugins for Day One export

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump
- Matching algorithm can be configured in settings
- All template placeholders can now use the "printf" formatting that %title and %note have, allowing for padding, prefixes, etc.
- Move default locations for doing file and backups to ~/.local/share/doing
- `doing show --menu` will only offer tags that exist after any tag/search filters have been run
- `doing show @tag` with `--menu` will first filter by the @tag, then do an OR search for tags selected from the menu

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed
- Preserve colors when wrapping text to new lines
- Tag highlighting errors
- Template options specified in views were being overriden by options in templates. View config now has precedence, but will fall back to template config for missing keys

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed

### 2.1.3

#### NEW

- BREAKING CHANGE: custom classes for Section (hash) and Items (Array). @content is still a regular Hash. Sections have methods :original and :items. This will affect plugins as wwid.content[section][:items] is now wwid[section].items (same for :original)
- `doing config set -r key.path` will delete a key from any config file, removing empty parent keys
- `config list` will list detected .doingrc files and the main config file in order of precedence - refactoring
- When modifying start dates or @done dates via an editor command, natural language strings can be used and will be parsed into doing-formatted dates automatically
- When editor is invoked, entry titles include start date, which can be modified
- `--before`, `--after`, and `--from` date filters for select command
- `--from` flag for `doing today` and `doing yesterday`, filter by time range
- `--from` flag for `doing search`, filter by date/time range
- Commands that accept `--before`, `--after`, and `--from` can now filter on time ranges. If the date string given contains only a time (no day or date), it will be interpreted as a time range, meaning the date isn't filtered, but only entries within the time range are shown/processed
- Add %duration placeholder to template variables
- Add `interval_format` setting to config (applies to root or any view/template) to set intervals/durations to human (2h 15m) or text (00:02:15)
- Add `duration` key to config (root or view/template). If set to true, will display durations by default (no need for `--duration`)
- Most display commands now have a `--duration` flag that will display an elapsed time if the entry is not marked @done

#### IMPROVED

- Config -o raw outputs value as YAML if result is a Hash/mapping, unquoted string if a single value, comma-separated list if it's an Array.
- Config -o json no longer includes key, only value.
- System agnostic method for checking available executables (pager, editor)
- Using `config set` and selecting a local config will no longer write the entire config to the local .doingrc. Instead, a nested path to the particular setting will be added to the config file.
- Config set will create missing keys. Fuzzy matching will work until the path fails, then path elements after that point will be added as verbatim keys to the specified configuration (with confirmation)
- Make menus only as tall as needed, so 5 options don't take up the whole screen
- Better word wrap for long note lines

#### FIXED

- `finish --took 60m` is supposed to backdate the start date if needed to finish at the current time and maintain an elapsed time
- If an editor was specified for config (or default as fallback) with command line options (e.g. `emacs -nw`), Doing would fail to recognize that the executable was available.

### 2.0.25

#### NEW

- `doing config set` to set single config values from command line
- BREAKING CHANGE: Moves ~/.doingrc to ~/.config/doing/config.yml
- BREAKING CHANGE: convert config flags to subcommands, e.g. `doing config --udpate` => `doing config update`, and `doing config --dump` => `doing config dump`

### 2.0.24

- include fzf source directly, in case git isn't installed
- fall back to installing fzf with sudo on error

### 2.0.20

#### IMPROVED

- completion script generator refactor and progress bars

#### FIXED

- compile fzf for current operating system

### 2.0.19

#### FIXED

- Remove any coloring before writing to doing file

### 2.0.18

#### FIXED

- Escape codes being included in doing file

### 2.0.17

#### IMPROVED

- Improvements to %title formatting and wrapping

### 2.0.16

- Test release to validate git flow automation

### 2.0.13

#### FIXED

- Remove amatch gem dependency due to compatibility issues with Windows systems (also removes `--fuzzy` option from all search commands)

### 2.0.11

#### NEW

- Append `/r` to tag transforms to replace original tag

#### FIXED

- Autotag tag transform fixes

### 2.0.10

#### NEW

- Add 'timer_format' config with 'human' option for tag totals
- If `doing view` and `doing show` are confused, offer option to run the other command
- `doing completion` to generate shell completion scripts for zsh, bash, and fish
- `--search` and `--not` for cancel command
- `--case` flag for commands with `--search`. Can be (c)ase-sensitive, (i)nsensitive, or (s)mart (default smart, case insensitive unless search string contains uppercase letters)
- Add `--exact` flag to all commands with `--search` flag to force exact matching without requiring single quote prefix
- Add `--not` flag to all commands with filters (`--tag`, `--search`, `--before`, etc.) to negate the filter and return entries NOT matched

#### IMPROVED

- More command line feedback
- Error formatting and output
- Add subcommand completion for `doing help` in fish shell
- Logging and error handling

#### FIXED

- Zsh completion not outputting results
- Remove `--[no]` from non-negatable options
- `doing plugins -t export -c` not outputting columns
- View config not respecting tag_order setting
 
### 2.0.3.pre

#### NEW

- Import calendar events from Calendar.app on macOS
- `doing config --update` will add newly added config keys to your existing config file (handy with plugins that define their own config keys)
- Add %idnote template placeholder for "indented note" (entire note indented one tab)
- (loosely printf-esque) formatting options for `%note` template placeholder
- `--interactive` mode to act on results of `doing grep`
- Printf formatting for title and date
- Doing import plugin
- Plugins command to list plugins
- `--dump` option for `doing config` to output a key.path config key as JSON, YAML, or raw output
- `--no-color` global flag
- Log levels, with `--quiet` and `--verbose` global flags
- Convert CLI messaging to Logger-based system
- Use DOING_DEBUG, DOING_QUIET, or DOING_LOG_LEVEL environment variables to specify log levels before configuration is read
- Hooks, register plugins to run based on events
- --[no-]pager and paginate: config option to enable paging output
- Never_finish and never_time config options to prevent items matching tags/sections from ever receiving @done (never_finish) or @done timestamp (never_time) - More configuration refactoring

#### IMPROVED

- Timeline output formatting
- Major plugin architecture refactoring
- Fix regression where notes stored in doing file were outdented, breaking TaskPaper compatibility
- When accepting a date filter, allow end date to be in the future
- If an edited item has no changes, don't update/output notification - Don't start with query when using grep `--interactive`
- Select menu item formatting
- Output wrapping for terminal display
- Redirect warn to STDOUT when run with `--stdout`
- Fish autocomplete
- `--config_file` global flag deprected, now uses $DOING_CONFIG environment variable so that config overrides can be available before the initial configuration is run
- When `--stdout` or not a TTY, no color or output formatting
- Highlight tags when showing results. Because it looks nice.
- `--tag` and `--search` for `doing note`
- View/section fuzzy guessing
- Error reporting
- If `doing config` finds local doingrc files, offers a menu for editing
- More filtering options for `doing finish`
- Doing done accepts `--unfinished` flag to finish last entry not marked @done (instead of last entry)
- Doing done accepts `--note` flag to append a note when completing an entry

#### FIXED

- Multi-word unquoted arguments to add_section being truncated
- Show `--from` with date span
- Handling of arbitrary times in natural language dates
- Backward scope of since command with arbitrary times
- `doing rotate --keep` wasn't respecting keep value

### 1.0.93

#### FIXED

- Gemfile error

### 1.0.91

#### NEW

- "taskpaper" format available for all output options
- "markdown" format available for all output commands (GFM-style task list, customizable template)
- `--rename` option for tag command to replace tags
- `--regex` option for tag command, for `--remove` and `--rename`

### 1.0.90

#### IMPROVED

- doing finish `--auto` now pulls from all sections, not just the section of the target entry

#### FIXED

- Minor fix for shell command in doing select
- Fix for doing finish `--auto` when matched item is last in list

### 1.0.89

#### NEW

- Pretty print JSON output
- `--no-menu` option for select command to use `--query` as a filter and act on matching entries without displaying menu

### 1.0.88

#### IMPROVED

- Add `--before` and `--after` time search to yesterday command
- Add `--before` and `--after` date search to search/grep command
- Add `--tag_order` to yesterday command

### 1.0.87

#### IMPROVED

- Add leading spaces to make %shortdate align properly, at least for the last week
- Add `--tag`, `--bool`, and `--search` to view command
- Add `--before` and `--after` date search to view command
- Add `--before` and `--after` date search to show command
- Add `--before` and `--after` time search to today command
- Add `--search` filter to show command
- More alignment/formatting fixes for %shortdate

### 1.0.86

#### IMPROVED

- Add `count` config option for templates->recent

### 1.0.85

#### IMPROVED

- Add `--before` DATE_STRING to archive and rotate commands
- Only create on rotate file per day, merge new entries into existing file

#### FIXED

- Fix `--auto` for finish command

### 1.0.84

#### NEW

- `rotate` command for archiving entries to new file

#### FIXED

- Fixed current_section config key not being honored in some commands

### 1.0.83

#### FIXED

- Fixes for `doing view` options, additional config keys for views

### 1.0.82

#### FIXED

- Bugfixes

### 1.0.81

#### IMPROVED

- fzf menu improvements
- allow multiple selections `doing select` action menu

### 1.0.80

#### IMPROVED

- Convert all menus to fzf screens

### 1.0.79

#### IMPROVED

- Wildcard tag removal using `doing select -t "tag*" -r`
- fzf menu display polish

#### FIXED

#### FIXED

- Gem missing fzf

### 1.0.78

#### IMPROVED

- If no action is specified with select command, an interactive menu is
presented
- add output action select command with formatting and save options
- Don't link URLs in html output that don't have a protocol

### 1.0.76

#### IMPROVED

- Refine editing multiple selections (doing select)

### 1.0.74

#### NEW

- Add `--tag` and `--search` flags to tag command to tag all entries matching search terms
- Add since command, which is the same as `doing on tuesday to now` but `doing since tuesday` just feels more intuitive. 

### 1.0.73

#### FIXED

- Fix for timeline output

### 1.0.72

#### NEW

- Add `doing select` to show menu of all tasks, searchable with fuzzy matching and the ability to perform certain tasks on multiple selections.

### 1.0.71

#### FIXED

- Fix for template command not working at all

### 1.0.70

#### FIXED

- Fix for `doing done --took 30m` setting the wrong @done timestamp when completing previous item

### 1.0.69

#### IMPROVED

- Add `--unfinished` option to finish and cancel commands

### 1.0.68

#### FIXED

- Fix error in `doing show --sort` argument parsing

### 1.0.67

#### FIXED

- Gem packaging error

### 1.0.66

#### IMPROVED

- More flexible boolean specification, can be: all, and, any, or, not, or none

#### FIXED

- Fix for some long flags being interpreted as arrays instead of strings
- Fix for archive command not removing original entries from archived section

### 1.0.65

#### IMPROVED

- Prevent duplicates/overlapping entries when importing

### 1.0.64

#### NEW

- Initial import feature for Timing.app reports

### 1.0.63

#### IMPROVED

- If `doing done --took=X` results in completion date greater than current time, use current time as completion date and backdate the entry's timestamp to fit

### 1.0.62

#### FIXED

- `doing done` with `--took=` and without `--back=` should set end time to start date plus `--took` value

### 1.0.61

#### IMPROVED

- Add `--search` filter to `doing archive`

### 1.0.60

#### FIXED

- Default value for `doing again --bool` was ALL, should be AND

### 1.0.59

#### IMPROVED

- Improvements to `doing again --tag=` functionality

### 1.0.58

#### IMPROVED

- Finish previous task if `doing again` and not already completed

### 1.0.57

#### IMPROVED

- Unit tests

### 1.0.56

#### IMPROVED

- Tag command tests

#### FIXED

- Doing not reading per-directory .doingrc configs

### 1.0.55

#### NEW

- Added config_editor_app setting to config so you can have
- A parenthetical at the end of an entry title becomes an attached
- `--editor` flag for `doing last` to edit last entry
- `--tag=` flag to filter `doing last` by tag
- `--search=` to filter `doing last` by text/regex search
- `--search=` for `doing finish`, finish last X entries matching search
- Add `tags_color` as a primary config key to highlight @tags in displayed entries

#### IMPROVED

- Clean up command line help
- `--editor` improvements for all commands that use it

#### FIXED

- Doing finish `--took` throwing error
- Doing tag `--remove` was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date

#### IMPROVED

- Add `--no-color` option to view command
- Add `--tag` to show for compatibility

#### FIXED

- Error running finish without `--tag` flag
- `--archive` flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry

#### FIXED

- `--archive` flag on finish, done, and cancel causing error

### 1.0.49

#### FIXED

- Fix for missing date on @done tags

### 1.0.48

#### FIXED

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

#### IMPROVED

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

#### IMPROVED

- Code cleanup

### 1.0.45

#### IMPROVED

- Only execute run_after script if changes are written

### 1.0.44

#### IMPROVED

- Remove unnecessary console logging

### 1.0.43

#### NEW

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

#### FIXED

- Fix note indentation in doing file

### 1.0.41

#### FIXED

- Fix for repeated backreferences in tag transform

### 1.0.40

#### IMPROVED

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

#### NEW

- Tag transforms
- Option to sort tags by name in `--totals`

### 1.0.33

#### FIXED

- Gem dependency updates

### 1.0.30

#### FIXED

- Fix for array comparison error

### 1.0.29

#### FIXED

- Bugfixes

### 1.0.28

#### IMPROVED

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

#### IMPROVED

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

#### IMPROVED

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

#### IMPROVED

#### IMPROVED

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

#### IMPROVED

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

#### IMPROVED

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

#### IMPROVED

- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

#### FIXED

- Fix handling of "local" config files, allowing per-project configurations

### 1.0.21

#### NEW

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)

#### FIXED

- CSS fix

### 1.0.20

#### NEW

- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

#### IMPROVED

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS

### 1.0.19

#### IMPROVED

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

#### IMPROVED

- Loosened up the template color resetting a bit more

#### FIXED

- Fix `undefined method [] for nil class` error in `doing view`

### 1.0.17

#### NEW

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

#### FIXED

- Fixes overzealous color resetting

### 1.0.15

#### FIXED

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

#### IMPROVED

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

#### FIXED

- Fix gsub error in doing meanwhile

### 1.0.8pre

#### NEW

- added doing on command
- Added autotagging to tag command
- JSON output option to view commands
- date filtering, improved date language
- let view templates define output format (csv, json, html, template)

#### IMPROVED

- add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

#### IMPROVED

- Slightly fuzzier searching in the grep command
- cleaner exits, `only_timed` key for view configs
- making the note command append new notes better, and load existing notes in the editor if `-e` is called
- handle multiple tag input in `show` tag filter
- Global tag operations, better reporting

#### FIXED

- fix for `-v` option

### 1.0.4pre

#### IMPROVED

- Improved HTML output
- `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
- add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
- fix for 1.8.7 `Dir.home` issue
- version bump
- don't show tag totals with zero times
- zsh completion for doing
- HTML styling
- `--only_timed` option
- added zsh completion file to `README.md`
- add zsh completion file

### 1.0.3pre

#### IMPROVED

- `done` command: making `--took` modify start time if `--back` isn't specified
- Cleaned up time totals, improved HTML output
- fixes for `--back` and `--took` parsing
- Adding more complete terminal reporting to archive command

### 1.0.0pre

#### IMPROVED

- Skipped ahead in the version numbering. Because I don't care.
- Added a `note` command and `--note` flags for entry creation commands

### 0.2.6pre

#### IMPROVED

- `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
- Add tests for Darwin to hide OS X-only features on other systems
- `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
- `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
- Basic command line reporting
- `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
- `doing grep` for searching by text or regex

### 0.2.5

#### IMPROVED

- Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
- Add section label to archived tasks automatically, excepting `Currently` section
- Today outputs and backdate for finish
- HTML styling and fix for 1.8.7 HAML errors
- Look, HTML output! (`--output html`)
- Also, `--output csv`
- let doing `archive` function on all sections
- option to exclude date from _@done_,  
- output newlines in sections and views
- Flagging (`doing mark`)
- fix for view/section guess error
- Adding tag filtering to archive command (`doing archive \@done`)
- `doing yesterday`
- `doing done -r` to remove last doing tag (optionally from `-s Section`)
- Add `-f` flag to specify alternate doing file
- `meanwhile` command

### 0.2.1

#### IMPROVED

- CSV output for show command (`--csv`)
- HTML output for show command (`--output html`)
- fuzzy searching for all commands that specify a view. 
- In the terminal, you'll see "Assume you meant XXX" to show what match it found, but this is output to STDERR (and won't show up if you're redirecting the output or using it in GeekTool, etc.)
- `tags_color` in view config to highlight tags at the end of the lines. Can be set to any of the `%colors`.
- Basic time tracking. 
- `-t` on `show` and `view` will turn on time calculations
- Intervals between timestamps and dated _@done_ tags are calculated for each line, if the tag exists. 
- You must include a `%interval` token in the appropriate template for it to show
- _@start(date)_ tags can optionally be used to override the timestamp in the calculation
- Any other tags in the line have that line's total added to them
- Totals for tags can be displayed at the end of output with `--totals`


### 0.2.0

#### IMPROVED

- `doing done` without argument tags last entry done
- `-a` archives them
- `doing finish` or `doing finish X` marks last X entries done
- `-a` archives them
- `doing tag tag1 [tag2]` tags last entry or `-c X` entries
- `doing tag -r tag1 [tag2]` removes said tag(s)
- custom views additions
- custom views can include `tags` and `tags_bool`
- `tags` is a space-separated list of tags to filter the results by
- `tags_bool` defines `AND` (all tags must exist), `OR` (any tag exists), or `NONE` (none of the tags exist)
- `order` key (`asc` or `desc`) defines output sort order by date
- section key can be set to `All` to combine sections
- `doing show` updates
- accepts `all` as a section
- arguments following section name are tags to filter by
- `-b` sets boolean (`AND`, `OR`, `NONE`) or (`ALL`, `ANY`, `NONE`) (default `OR`/`ANY`)
- use `-c X` to limit results
- use `-s` to set sort order (`asc` or `desc`)
- use `-a` to set age (`newest` or `oldest`)
- fuzzy section guessing when specified section isn't found
- fuzzy view guessing for `doing view` command

### 0.1.9

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later` and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)
- `doing views` shows all available custom views
- `doing view` without a view name will let you choose a view from a menu
- `doing archive` fixed so that `-k X` works to keep `X` number of entries in the section

### 0.1.7

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)

doing### 2.1.30

2022-02-16 07:18

#### IMPROVED

- `doing changes` does a better job of parsing a lookup string like '>= 2.1.10 < 2.1.15'

#### FIXED

- System agnostic platform detection, so commands that check for Darwin won't error out on other systems
- `doing completions` debugging code

### 2.1.29

2022-02-14 12:42

#### IMPROVED

- `doing changes --interactive` will load up a changelog viewer using fzf. Because it makes me happy, that's why.

### 2.1.28

2022-02-14 11:39

#### FIXED

- Lines merging in `doing changes --changes` output

### 2.1.27

2022-02-14 06:04

#### NEW

- `doing finish --update` will overwrite any existing @done tag with a new date (current time or set with `--at` or `--back`)

#### IMPROVED

- Code refactoring and cleanup
- Include release dates in `doing changes` output when available
- Allow various naming conventions for %color strings in templates. Now `boldwhite`, `brightwhite`, `bg_bold_cyan`, and `bold_bg_cyan` all work (for example)
- Common flags (e.g. --search, --tag) found on multiple commands consolidated and help descriptions matched
- `commands_accepting` now accepts multiple arguments and a `--bool` flag
- `changes` command can now output changes only (no version numbers) and defaults to raw Markdown if not a TTY or the `--md` flag is used
- `doing archive` now accepts `--after` and `--from` date filters

#### FIXED

- Some flag descriptions in help
- Editor detection

### 2.1.26

2022-01-23 16:14

#### NEW

- Use plugins.hidden_commands in configuration to disable any command (array of command names). Note that some commands use aliases and the first name should be used.
- `doing commands [add|remove]` allows interactive enabling and disabling of default and custom commands

#### IMPROVED

- Moved all commands into separate files for management

#### FIXED

- Changelog command regex too greedy when parsing changelog

### 2.1.25

2022-01-23 09:25

### 2.1.24

2022-01-22 17:27

#### IMPROVED

- Minor update to Fish completion script

#### FIXED

- Changelog formatting issue

### 2.1.23

2022-01-22 15:52

#### NEW

- All display commands (except view) now accept `--config_template TEMPLATE_KEY` to override that commands default template.
- Display commands accept `--template`, which takes a template string containing %placeholders and overrides the commands default template output. Affects grep, last, on, recent, show, since, today, yesterday

#### IMPROVED

- With complete examples in the help output for most commands, `doing help` almost always requires scrolling up. It now automatically paginates using your system $PAGER (or best detected option).
- `doing tags` takes a MAX_COUNT argument to limit results when searching
- `doing tags --line` flag to output tags in a single line
- Mostly for my own use, `doing changes` (which views the changelog) now accepts `--lookup VERSION` and `--search SEARCH_PATTERN`
- `doing changes --lookup` accepts `"< 2.1 > 2.0"`, `"2.1.10-2.2"`, a specific version, or a version number with wildcards
- When registering hooks, you can pass an array to register a block for multiple events, assuming the events provide the same block arguments (like post_entry_added and post_entry_updated)

#### FIXED

- Running `--tag "@doing"` wouldn't work where `--tag "doing"` would. Now properly ignoring @ symbols

### 2.1.22

2022-01-21 14:53

### 2.1.21

2022-01-20 12:05

#### FIXED

- Custom types not available to custom commands

### 2.1.20

2022-01-20 11:49

#### NEW

- Autotag option for interactive `doing select` menu
- (Breaking change) Made the later command an optional plugin, see wiki for how to install (and create) custom commands
- Config setting doing_file_sort (asc or desc) determines the sort order of entries in the actual Doing file. Has no effect on other operations, just allows you to store the file with newest entries at top (desc) or bottom (asc).

#### IMPROVED

- Autotag improvements
- If doing is run without a command but with arguments, execute it as if you'd run `doing now`, passing the arguments to that. So you can just write "doing this thing" instead of "doing now this thing", as long as the first word of the arguments is not a recognized command.

#### FIXED

- `doing again` should only mark the original repeating entry @done, not search for the last unfinished entry
- Error when using `doing finish --auto`
- `doing on wed` when today is wednesday not returning results
- Using `config set` with a false value deleted the key from config
- `config set` with true or false value was inserting a quoted string
- Entries were not being sorted (at all) within sections when writing the Doing file

### 2.1.19

2022-01-18 08:40

#### FIXED

- Search highlighting error with some pattern searches
- Reverse sort of items in menu from `--interactive` flags
- Nil error when `--interactive` was called without search results

### 2.1.18

Build automation test

### 2.1.17

2022-01-18 07:26

#### NEW

- `--hilite` option for `doing search` to highlight matches in search results (terminal output only)
- `--hilite` flag for `show` and `view` to highlight results when used with `--search`

#### IMPROVED

- Show preview of up to 5 items when confirming a delete operation so you actually know what you're deleting
- Allow `--ask` when creating new entry via STDIN pipe
- Tab completion for known tags when creating an entry interactively
- Add purple as an alias for magenta in template colors

#### FIXED

- Clear STDIN before requesting input

### 2.1.16

2022-01-18 02:45

#### NEW

- `doing done --from "3pm to 3:15pm"` to set start and end times with natural language string

#### IMPROVED

- Running `doing tag` without arguments takes command line input
- If `doing now` or `doing later` are run without arguments, interactively request necessary information (you can still use `--editor` to edit in your preferred editor)
- Tab completion for tags when entering at prompt
- Use readline when requesting input text, better editing features
- `doing done --at` no longer overrides `--back`

#### FIXED

- `doing select` -> output formatted empty output
- Sort items by date when using `doing select --editor` (was loading in selection order instead)
- Ruby 2.7 error in template output (.empty? on FalseClass)
- Don't add empty entry when cancelling `--editor`
- Batch editing bugs

### 2.1.15

2022-01-17 07:25

#### NEW

- When completing an entry, if the elapsed time would be greater than a (configurable) amount, doing will now ask for confirmation and allow you to enter a new duration before setting the @done date

#### IMPROVED

- When entering intervals, you can now use 1h30m in addition to 1.5h or 90m
- Date expansion works in more circumstances
- You can include date tags with natural language values when adding tags via `doing select`

#### FIXED

- Tags containing values with spaces no longer cause errors

### 2.1.14

#### NEW

- All commands that accept `--note` now accept `--ask`, which requests input via readline after creating the note. Multiple lines are allowed, hit return twice to end editing. Works alongside `--note` and `--editor`

#### IMPROVED

- Implement `--search` and `--from` filtering for import plugins
- UTC format date strings in select menus for consistency (was relative date formatting)
- Don't populate the fzf search with `--search`, it's already filtered. Separated `--query` from `--search` if you do want to populate the query string in addition to `--search` filtering
- When showing relative dates, don't include the year if the date is the previous year but a later month than the current month (less than a year old)
- When using `--editor` while adding an entry, include any note specified on the command line or via `--ask` for further editing

### 2.1.13

#### NEW

- `--val` flag for all display commands, allows tag value queries. Tag values are contained in parenthesis after the tag, e.g. @progress(50). Queries look like `--val "done < two weeks ago"`, "project *= oracle" or "progress >= 50". Wildcards allowed in value, comparators can be <, >, <=, >=, ==, *= (contains), ^= (begins with), $= (ends with). Numeric and date comparisons are detected automatically. Text comparisons are case insensitive. `--val` can be used multiple times in a command and you can use `--bool` to specify AND, OR, or NOT (default AND)
- `doing tag` now accepts a `--value` flag to define a value for a single tag, e.g. @tag(value)

#### FIXED

- `doing last --editor` errors

### 2.1.12

#### NEW

- Tag_dir command creates/updates .doingrc files in the current directory with default_tags values. Then all entries created within that directory (or subdirs) get tagged with that value.
- Synonym triggers allow `*` and `?` wildcards
- Add `--delete` flag for `doing last` to delete last entry
- `--delete` and `--editor` flags for `doing search`, batch edit and delete
- Example hook to add new entries containing a certain tag to Day One
- New hooks: pre_entry_add, post_entry_added, post_entry_updated, post_entry_removed, pre_export

#### IMPROVED

- If you need to use a colon in an autotag transform pattern, you can split with double colon, e.g. pattern::replacement
- Arrays defined in local configurations merge with main config instead of overwriting

#### FIXED

- `doing tags --interactive` wasn't showing menu

### 2.1.10

#### NEW

- `--age` (oldest|newest) option for view command

### 2.1.9

#### IMPROVED

- Only attempt to install fzf if it doesn't exist on the system. In case of errors, this means a user can manually install fzf and still be able to access `--interactive` options

#### FIXED

- Rotate command only archiving half of requested items
- Frozen string error in doing import plugin

### 2.1.8

#### NEW

- Hidden command `doing commands_accepting` which shows all commands that accept a given option, e.g. `doing commands_accepting search` shows all commands that take a search filter
- Hidden command `doing changelog` which outputs a paginated, formatted version of the change history.

#### IMPROVED

- The output of `doing template --list` now shows the file type of each template
- Output templates can now be saved to a default location/filename using `doing template html --save`

#### FIXED

- Error running `doing recent` on certain older ruby versions

### 2.1.6

#### NEW

- `doing redo` undoes a redo
- `doing undo -i` offers a list of available versions for selection
- Multiple undo. Every time a command modifies the doing file, a backup is written. Running `doing undo` repeatedly steps back through history, `doing undo 5` jumps back 5 versions
- When resetting via `doing select`, prompt for a date string
- `doing reset` accepts a date string argument to use as start date instead of current time if provided
- `doing tags` lists tags used in any/all sections, sortable, with or without frequency counts
- `doing show --menu` offers an interactive menu for selecting section and tag filters
- All commands that accept a `--tag` filter can now handle wildcards in the tag names. * to match any number of characters, ? to match a single character.
- New boolean type for tag searches, PATTERN (which is now the default). Combine tags using symbols to create more complex boolean searches, e.g. "doing +coding -work"
- You can now define `date_tags` in config, an array of tags/patterns that will be recognized when parsing for natural language dates which are converted when saving new entries
- `--search` strings can contain quoted phrases and use +/- to require or ban terms, e.g. `--search 'doing +coding -writing'
- Interactive option for redo command
- Plugins for Day One export

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump
- Matching algorithm can be configured in settings
- All template placeholders can now use the "printf" formatting that %title and %note have, allowing for padding, prefixes, etc.
- Move default locations for doing file and backups to ~/.local/share/doing
- `doing show --menu` will only offer tags that exist after any tag/search filters have been run
- `doing show @tag` with `--menu` will first filter by the @tag, then do an OR search for tags selected from the menu

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed
- Preserve colors when wrapping text to new lines
- Tag highlighting errors
- Template options specified in views were being overriden by options in templates. View config now has precedence, but will fall back to template config for missing keys

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed

### 2.1.3

#### NEW

- BREAKING CHANGE: custom classes for Section (hash) and Items (Array). @content is still a regular Hash. Sections have methods :original and :items. This will affect plugins as wwid.content[section][:items] is now wwid[section].items (same for :original)
- `doing config set -r key.path` will delete a key from any config file, removing empty parent keys
- `config list` will list detected .doingrc files and the main config file in order of precedence - refactoring
- When modifying start dates or @done dates via an editor command, natural language strings can be used and will be parsed into doing-formatted dates automatically
- When editor is invoked, entry titles include start date, which can be modified
- `--before`, `--after`, and `--from` date filters for select command
- `--from` flag for `doing today` and `doing yesterday`, filter by time range
- `--from` flag for `doing search`, filter by date/time range
- Commands that accept `--before`, `--after`, and `--from` can now filter on time ranges. If the date string given contains only a time (no day or date), it will be interpreted as a time range, meaning the date isn't filtered, but only entries within the time range are shown/processed
- Add %duration placeholder to template variables
- Add `interval_format` setting to config (applies to root or any view/template) to set intervals/durations to human (2h 15m) or text (00:02:15)
- Add `duration` key to config (root or view/template). If set to true, will display durations by default (no need for `--duration`)
- Most display commands now have a `--duration` flag that will display an elapsed time if the entry is not marked @done

#### IMPROVED

- Config -o raw outputs value as YAML if result is a Hash/mapping, unquoted string if a single value, comma-separated list if it's an Array.
- Config -o json no longer includes key, only value.
- System agnostic method for checking available executables (pager, editor)
- Using `config set` and selecting a local config will no longer write the entire config to the local .doingrc. Instead, a nested path to the particular setting will be added to the config file.
- Config set will create missing keys. Fuzzy matching will work until the path fails, then path elements after that point will be added as verbatim keys to the specified configuration (with confirmation)
- Make menus only as tall as needed, so 5 options don't take up the whole screen
- Better word wrap for long note lines

#### FIXED

- `finish --took 60m` is supposed to backdate the start date if needed to finish at the current time and maintain an elapsed time
- If an editor was specified for config (or default as fallback) with command line options (e.g. `emacs -nw`), Doing would fail to recognize that the executable was available.

### 2.0.25

#### NEW

- `doing config set` to set single config values from command line
- BREAKING CHANGE: Moves ~/.doingrc to ~/.config/doing/config.yml
- BREAKING CHANGE: convert config flags to subcommands, e.g. `doing config --udpate` => `doing config update`, and `doing config --dump` => `doing config dump`

### 2.0.24

- include fzf source directly, in case git isn't installed
- fall back to installing fzf with sudo on error

### 2.0.20

#### IMPROVED

- completion script generator refactor and progress bars

#### FIXED

- compile fzf for current operating system

### 2.0.19

#### FIXED

- Remove any coloring before writing to doing file

### 2.0.18

#### FIXED

- Escape codes being included in doing file

### 2.0.17

#### IMPROVED

- Improvements to %title formatting and wrapping

### 2.0.16

- Test release to validate git flow automation

### 2.0.13

#### FIXED

- Remove amatch gem dependency due to compatibility issues with Windows systems (also removes `--fuzzy` option from all search commands)

### 2.0.11

#### NEW

- Append `/r` to tag transforms to replace original tag

#### FIXED

- Autotag tag transform fixes

### 2.0.10

#### NEW

- Add 'timer_format' config with 'human' option for tag totals
- If `doing view` and `doing show` are confused, offer option to run the other command
- `doing completion` to generate shell completion scripts for zsh, bash, and fish
- `--search` and `--not` for cancel command
- `--case` flag for commands with `--search`. Can be (c)ase-sensitive, (i)nsensitive, or (s)mart (default smart, case insensitive unless search string contains uppercase letters)
- Add `--exact` flag to all commands with `--search` flag to force exact matching without requiring single quote prefix
- Add `--not` flag to all commands with filters (`--tag`, `--search`, `--before`, etc.) to negate the filter and return entries NOT matched

#### IMPROVED

- More command line feedback
- Error formatting and output
- Add subcommand completion for `doing help` in fish shell
- Logging and error handling

#### FIXED

- Zsh completion not outputting results
- Remove `--[no]` from non-negatable options
- `doing plugins -t export -c` not outputting columns
- View config not respecting tag_order setting
 
### 2.0.3.pre

#### NEW

- Import calendar events from Calendar.app on macOS
- `doing config --update` will add newly added config keys to your existing config file (handy with plugins that define their own config keys)
- Add %idnote template placeholder for "indented note" (entire note indented one tab)
- (loosely printf-esque) formatting options for `%note` template placeholder
- `--interactive` mode to act on results of `doing grep`
- Printf formatting for title and date
- Doing import plugin
- Plugins command to list plugins
- `--dump` option for `doing config` to output a key.path config key as JSON, YAML, or raw output
- `--no-color` global flag
- Log levels, with `--quiet` and `--verbose` global flags
- Convert CLI messaging to Logger-based system
- Use DOING_DEBUG, DOING_QUIET, or DOING_LOG_LEVEL environment variables to specify log levels before configuration is read
- Hooks, register plugins to run based on events
- --[no-]pager and paginate: config option to enable paging output
- Never_finish and never_time config options to prevent items matching tags/sections from ever receiving @done (never_finish) or @done timestamp (never_time) - More configuration refactoring

#### IMPROVED

- Timeline output formatting
- Major plugin architecture refactoring
- Fix regression where notes stored in doing file were outdented, breaking TaskPaper compatibility
- When accepting a date filter, allow end date to be in the future
- If an edited item has no changes, don't update/output notification - Don't start with query when using grep `--interactive`
- Select menu item formatting
- Output wrapping for terminal display
- Redirect warn to STDOUT when run with `--stdout`
- Fish autocomplete
- `--config_file` global flag deprected, now uses $DOING_CONFIG environment variable so that config overrides can be available before the initial configuration is run
- When `--stdout` or not a TTY, no color or output formatting
- Highlight tags when showing results. Because it looks nice.
- `--tag` and `--search` for `doing note`
- View/section fuzzy guessing
- Error reporting
- If `doing config` finds local doingrc files, offers a menu for editing
- More filtering options for `doing finish`
- Doing done accepts `--unfinished` flag to finish last entry not marked @done (instead of last entry)
- Doing done accepts `--note` flag to append a note when completing an entry

#### FIXED

- Multi-word unquoted arguments to add_section being truncated
- Show `--from` with date span
- Handling of arbitrary times in natural language dates
- Backward scope of since command with arbitrary times
- `doing rotate --keep` wasn't respecting keep value

### 1.0.93

#### FIXED

- Gemfile error

### 1.0.91

#### NEW

- "taskpaper" format available for all output options
- "markdown" format available for all output commands (GFM-style task list, customizable template)
- `--rename` option for tag command to replace tags
- `--regex` option for tag command, for `--remove` and `--rename`

### 1.0.90

#### IMPROVED

- doing finish `--auto` now pulls from all sections, not just the section of the target entry

#### FIXED

- Minor fix for shell command in doing select
- Fix for doing finish `--auto` when matched item is last in list

### 1.0.89

#### NEW

- Pretty print JSON output
- `--no-menu` option for select command to use `--query` as a filter and act on matching entries without displaying menu

### 1.0.88

#### IMPROVED

- Add `--before` and `--after` time search to yesterday command
- Add `--before` and `--after` date search to search/grep command
- Add `--tag_order` to yesterday command

### 1.0.87

#### IMPROVED

- Add leading spaces to make %shortdate align properly, at least for the last week
- Add `--tag`, `--bool`, and `--search` to view command
- Add `--before` and `--after` date search to view command
- Add `--before` and `--after` date search to show command
- Add `--before` and `--after` time search to today command
- Add `--search` filter to show command
- More alignment/formatting fixes for %shortdate

### 1.0.86

#### IMPROVED

- Add `count` config option for templates->recent

### 1.0.85

#### IMPROVED

- Add `--before` DATE_STRING to archive and rotate commands
- Only create on rotate file per day, merge new entries into existing file

#### FIXED

- Fix `--auto` for finish command

### 1.0.84

#### NEW

- `rotate` command for archiving entries to new file

#### FIXED

- Fixed current_section config key not being honored in some commands

### 1.0.83

#### FIXED

- Fixes for `doing view` options, additional config keys for views

### 1.0.82

#### FIXED

- Bugfixes

### 1.0.81

#### IMPROVED

- fzf menu improvements
- allow multiple selections `doing select` action menu

### 1.0.80

#### IMPROVED

- Convert all menus to fzf screens

### 1.0.79

#### IMPROVED

- Wildcard tag removal using `doing select -t "tag*" -r`
- fzf menu display polish

#### FIXED

#### FIXED

- Gem missing fzf

### 1.0.78

#### IMPROVED

- If no action is specified with select command, an interactive menu is
presented
- add output action select command with formatting and save options
- Don't link URLs in html output that don't have a protocol

### 1.0.76

#### IMPROVED

- Refine editing multiple selections (doing select)

### 1.0.74

#### NEW

- Add `--tag` and `--search` flags to tag command to tag all entries matching search terms
- Add since command, which is the same as `doing on tuesday to now` but `doing since tuesday` just feels more intuitive. 

### 1.0.73

#### FIXED

- Fix for timeline output

### 1.0.72

#### NEW

- Add `doing select` to show menu of all tasks, searchable with fuzzy matching and the ability to perform certain tasks on multiple selections.

### 1.0.71

#### FIXED

- Fix for template command not working at all

### 1.0.70

#### FIXED

- Fix for `doing done --took 30m` setting the wrong @done timestamp when completing previous item

### 1.0.69

#### IMPROVED

- Add `--unfinished` option to finish and cancel commands

### 1.0.68

#### FIXED

- Fix error in `doing show --sort` argument parsing

### 1.0.67

#### FIXED

- Gem packaging error

### 1.0.66

#### IMPROVED

- More flexible boolean specification, can be: all, and, any, or, not, or none

#### FIXED

- Fix for some long flags being interpreted as arrays instead of strings
- Fix for archive command not removing original entries from archived section

### 1.0.65

#### IMPROVED

- Prevent duplicates/overlapping entries when importing

### 1.0.64

#### NEW

- Initial import feature for Timing.app reports

### 1.0.63

#### IMPROVED

- If `doing done --took=X` results in completion date greater than current time, use current time as completion date and backdate the entry's timestamp to fit

### 1.0.62

#### FIXED

- `doing done` with `--took=` and without `--back=` should set end time to start date plus `--took` value

### 1.0.61

#### IMPROVED

- Add `--search` filter to `doing archive`

### 1.0.60

#### FIXED

- Default value for `doing again --bool` was ALL, should be AND

### 1.0.59

#### IMPROVED

- Improvements to `doing again --tag=` functionality

### 1.0.58

#### IMPROVED

- Finish previous task if `doing again` and not already completed

### 1.0.57

#### IMPROVED

- Unit tests

### 1.0.56

#### IMPROVED

- Tag command tests

#### FIXED

- Doing not reading per-directory .doingrc configs

### 1.0.55

#### NEW

- Added config_editor_app setting to config so you can have
- A parenthetical at the end of an entry title becomes an attached
- `--editor` flag for `doing last` to edit last entry
- `--tag=` flag to filter `doing last` by tag
- `--search=` to filter `doing last` by text/regex search
- `--search=` for `doing finish`, finish last X entries matching search
- Add `tags_color` as a primary config key to highlight @tags in displayed entries

#### IMPROVED

- Clean up command line help
- `--editor` improvements for all commands that use it

#### FIXED

- Doing finish `--took` throwing error
- Doing tag `--remove` was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date

#### IMPROVED

- Add `--no-color` option to view command
- Add `--tag` to show for compatibility

#### FIXED

- Error running finish without `--tag` flag
- `--archive` flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry

#### FIXED

- `--archive` flag on finish, done, and cancel causing error

### 1.0.49

#### FIXED

- Fix for missing date on @done tags

### 1.0.48

#### FIXED

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

#### IMPROVED

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

#### IMPROVED

- Code cleanup

### 1.0.45

#### IMPROVED

- Only execute run_after script if changes are written

### 1.0.44

#### IMPROVED

- Remove unnecessary console logging

### 1.0.43

#### NEW

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

#### FIXED

- Fix note indentation in doing file

### 1.0.41

#### FIXED

- Fix for repeated backreferences in tag transform

### 1.0.40

#### IMPROVED

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

#### NEW

- Tag transforms
- Option to sort tags by name in `--totals`

### 1.0.33

#### FIXED

- Gem dependency updates

### 1.0.30

#### FIXED

- Fix for array comparison error

### 1.0.29

#### FIXED

- Bugfixes

### 1.0.28

#### IMPROVED

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

#### IMPROVED

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

#### IMPROVED

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

#### IMPROVED

#### IMPROVED

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

#### IMPROVED

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

#### IMPROVED

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

#### IMPROVED

- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

#### FIXED

- Fix handling of "local" config files, allowing per-project configurations

### 1.0.21

#### NEW

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)

#### FIXED

- CSS fix

### 1.0.20

#### NEW

- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

#### IMPROVED

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS

### 1.0.19

#### IMPROVED

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

#### IMPROVED

- Loosened up the template color resetting a bit more

#### FIXED

- Fix `undefined method [] for nil class` error in `doing view`

### 1.0.17

#### NEW

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

#### FIXED

- Fixes overzealous color resetting

### 1.0.15

#### FIXED

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

#### IMPROVED

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

#### FIXED

- Fix gsub error in doing meanwhile

### 1.0.8pre

#### NEW

- added doing on command
- Added autotagging to tag command
- JSON output option to view commands
- date filtering, improved date language
- let view templates define output format (csv, json, html, template)

#### IMPROVED

- add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

#### IMPROVED

- Slightly fuzzier searching in the grep command
- cleaner exits, `only_timed` key for view configs
- making the note command append new notes better, and load existing notes in the editor if `-e` is called
- handle multiple tag input in `show` tag filter
- Global tag operations, better reporting

#### FIXED

- fix for `-v` option

### 1.0.4pre

#### IMPROVED

- Improved HTML output
- `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
- add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
- fix for 1.8.7 `Dir.home` issue
- version bump
- don't show tag totals with zero times
- zsh completion for doing
- HTML styling
- `--only_timed` option
- added zsh completion file to `README.md`
- add zsh completion file

### 1.0.3pre

#### IMPROVED

- `done` command: making `--took` modify start time if `--back` isn't specified
- Cleaned up time totals, improved HTML output
- fixes for `--back` and `--took` parsing
- Adding more complete terminal reporting to archive command

### 1.0.0pre

#### IMPROVED

- Skipped ahead in the version numbering. Because I don't care.
- Added a `note` command and `--note` flags for entry creation commands

### 0.2.6pre

#### IMPROVED

- `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
- Add tests for Darwin to hide OS X-only features on other systems
- `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
- `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
- Basic command line reporting
- `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
- `doing grep` for searching by text or regex

### 0.2.5

#### IMPROVED

- Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
- Add section label to archived tasks automatically, excepting `Currently` section
- Today outputs and backdate for finish
- HTML styling and fix for 1.8.7 HAML errors
- Look, HTML output! (`--output html`)
- Also, `--output csv`
- let doing `archive` function on all sections
- option to exclude date from _@done_,  
- output newlines in sections and views
- Flagging (`doing mark`)
- fix for view/section guess error
- Adding tag filtering to archive command (`doing archive \@done`)
- `doing yesterday`
- `doing done -r` to remove last doing tag (optionally from `-s Section`)
- Add `-f` flag to specify alternate doing file
- `meanwhile` command

### 0.2.1

#### IMPROVED

- CSV output for show command (`--csv`)
- HTML output for show command (`--output html`)
- fuzzy searching for all commands that specify a view. 
- In the terminal, you'll see "Assume you meant XXX" to show what match it found, but this is output to STDERR (and won't show up if you're redirecting the output or using it in GeekTool, etc.)
- `tags_color` in view config to highlight tags at the end of the lines. Can be set to any of the `%colors`.
- Basic time tracking. 
- `-t` on `show` and `view` will turn on time calculations
- Intervals between timestamps and dated _@done_ tags are calculated for each line, if the tag exists. 
- You must include a `%interval` token in the appropriate template for it to show
- _@start(date)_ tags can optionally be used to override the timestamp in the calculation
- Any other tags in the line have that line's total added to them
- Totals for tags can be displayed at the end of output with `--totals`


### 0.2.0

#### IMPROVED

- `doing done` without argument tags last entry done
- `-a` archives them
- `doing finish` or `doing finish X` marks last X entries done
- `-a` archives them
- `doing tag tag1 [tag2]` tags last entry or `-c X` entries
- `doing tag -r tag1 [tag2]` removes said tag(s)
- custom views additions
- custom views can include `tags` and `tags_bool`
- `tags` is a space-separated list of tags to filter the results by
- `tags_bool` defines `AND` (all tags must exist), `OR` (any tag exists), or `NONE` (none of the tags exist)
- `order` key (`asc` or `desc`) defines output sort order by date
- section key can be set to `All` to combine sections
- `doing show` updates
- accepts `all` as a section
- arguments following section name are tags to filter by
- `-b` sets boolean (`AND`, `OR`, `NONE`) or (`ALL`, `ANY`, `NONE`) (default `OR`/`ANY`)
- use `-c X` to limit results
- use `-s` to set sort order (`asc` or `desc`)
- use `-a` to set age (`newest` or `oldest`)
- fuzzy section guessing when specified section isn't found
- fuzzy view guessing for `doing view` command

### 0.1.9

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later` and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)
- `doing views` shows all available custom views
- `doing view` without a view name will let you choose a view from a menu
- `doing archive` fixed so that `-k X` works to keep `X` number of entries in the section

### 0.1.7

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)

 and hitting tab will offer completions of subcommands and their options.'  command :completion do |c|
- When generating completion scripts using `doing completion --file FILE_PATH`, if the file specified is not in an auto-load directory for the shell type, offer to symlink the output to an appropriate directory

### 2.1.30

2022-02-16 07:18

#### IMPROVED

- `doing changes` does a better job of parsing a lookup string like '>= 2.1.10 < 2.1.15'

#### FIXED

- System agnostic platform detection, so commands that check for Darwin won't error out on other systems
- `doing completions` debugging code

### 2.1.29

2022-02-14 12:42

#### IMPROVED

- `doing changes --interactive` will load up a changelog viewer using fzf. Because it makes me happy, that's why.

### 2.1.28

2022-02-14 11:39

#### FIXED

- Lines merging in `doing changes --changes` output

### 2.1.27

2022-02-14 06:04

#### NEW

- `doing finish --update` will overwrite any existing @done tag with a new date (current time or set with `--at` or `--back`)

#### IMPROVED

- Code refactoring and cleanup
- Include release dates in `doing changes` output when available
- Allow various naming conventions for %color strings in templates. Now `boldwhite`, `brightwhite`, `bg_bold_cyan`, and `bold_bg_cyan` all work (for example)
- Common flags (e.g. --search, --tag) found on multiple commands consolidated and help descriptions matched
- `commands_accepting` now accepts multiple arguments and a `--bool` flag
- `changes` command can now output changes only (no version numbers) and defaults to raw Markdown if not a TTY or the `--md` flag is used
- `doing archive` now accepts `--after` and `--from` date filters

#### FIXED

- Some flag descriptions in help
- Editor detection

### 2.1.26

2022-01-23 16:14

#### NEW

- Use plugins.hidden_commands in configuration to disable any command (array of command names). Note that some commands use aliases and the first name should be used.
- `doing commands [add|remove]` allows interactive enabling and disabling of default and custom commands

#### IMPROVED

- Moved all commands into separate files for management

#### FIXED

- Changelog command regex too greedy when parsing changelog

### 2.1.25

2022-01-23 09:25

### 2.1.24

2022-01-22 17:27

#### IMPROVED

- Minor update to Fish completion script

#### FIXED

- Changelog formatting issue

### 2.1.23

2022-01-22 15:52

#### NEW

- All display commands (except view) now accept `--config_template TEMPLATE_KEY` to override that commands default template.
- Display commands accept `--template`, which takes a template string containing %placeholders and overrides the commands default template output. Affects grep, last, on, recent, show, since, today, yesterday

#### IMPROVED

- With complete examples in the help output for most commands, `doing help` almost always requires scrolling up. It now automatically paginates using your system $PAGER (or best detected option).
- `doing tags` takes a MAX_COUNT argument to limit results when searching
- `doing tags --line` flag to output tags in a single line
- Mostly for my own use, `doing changes` (which views the changelog) now accepts `--lookup VERSION` and `--search SEARCH_PATTERN`
- `doing changes --lookup` accepts `"< 2.1 > 2.0"`, `"2.1.10-2.2"`, a specific version, or a version number with wildcards
- When registering hooks, you can pass an array to register a block for multiple events, assuming the events provide the same block arguments (like post_entry_added and post_entry_updated)

#### FIXED

- Running `--tag "@doing"` wouldn't work where `--tag "doing"` would. Now properly ignoring @ symbols

### 2.1.22

2022-01-21 14:53

### 2.1.21

2022-01-20 12:05

#### FIXED

- Custom types not available to custom commands

### 2.1.20

2022-01-20 11:49

#### NEW

- Autotag option for interactive `doing select` menu
- (Breaking change) Made the later command an optional plugin, see wiki for how to install (and create) custom commands
- Config setting doing_file_sort (asc or desc) determines the sort order of entries in the actual Doing file. Has no effect on other operations, just allows you to store the file with newest entries at top (desc) or bottom (asc).

#### IMPROVED

- Autotag improvements
- If doing is run without a command but with arguments, execute it as if you'd run `doing now`, passing the arguments to that. So you can just write "doing this thing" instead of "doing now this thing", as long as the first word of the arguments is not a recognized command.

#### FIXED

- `doing again` should only mark the original repeating entry @done, not search for the last unfinished entry
- Error when using `doing finish --auto`
- `doing on wed` when today is wednesday not returning results
- Using `config set` with a false value deleted the key from config
- `config set` with true or false value was inserting a quoted string
- Entries were not being sorted (at all) within sections when writing the Doing file

### 2.1.19

2022-01-18 08:40

#### FIXED

- Search highlighting error with some pattern searches
- Reverse sort of items in menu from `--interactive` flags
- Nil error when `--interactive` was called without search results

### 2.1.18

Build automation test

### 2.1.17

2022-01-18 07:26

#### NEW

- `--hilite` option for `doing search` to highlight matches in search results (terminal output only)
- `--hilite` flag for `show` and `view` to highlight results when used with `--search`

#### IMPROVED

- Show preview of up to 5 items when confirming a delete operation so you actually know what you're deleting
- Allow `--ask` when creating new entry via STDIN pipe
- Tab completion for known tags when creating an entry interactively
- Add purple as an alias for magenta in template colors

#### FIXED

- Clear STDIN before requesting input

### 2.1.16

2022-01-18 02:45

#### NEW

- `doing done --from "3pm to 3:15pm"` to set start and end times with natural language string

#### IMPROVED

- Running `doing tag` without arguments takes command line input
- If `doing now` or `doing later` are run without arguments, interactively request necessary information (you can still use `--editor` to edit in your preferred editor)
- Tab completion for tags when entering at prompt
- Use readline when requesting input text, better editing features
- `doing done --at` no longer overrides `--back`

#### FIXED

- `doing select` -> output formatted empty output
- Sort items by date when using `doing select --editor` (was loading in selection order instead)
- Ruby 2.7 error in template output (.empty? on FalseClass)
- Don't add empty entry when cancelling `--editor`
- Batch editing bugs

### 2.1.15

2022-01-17 07:25

#### NEW

- When completing an entry, if the elapsed time would be greater than a (configurable) amount, doing will now ask for confirmation and allow you to enter a new duration before setting the @done date

#### IMPROVED

- When entering intervals, you can now use 1h30m in addition to 1.5h or 90m
- Date expansion works in more circumstances
- You can include date tags with natural language values when adding tags via `doing select`

#### FIXED

- Tags containing values with spaces no longer cause errors

### 2.1.14

#### NEW

- All commands that accept `--note` now accept `--ask`, which requests input via readline after creating the note. Multiple lines are allowed, hit return twice to end editing. Works alongside `--note` and `--editor`

#### IMPROVED

- Implement `--search` and `--from` filtering for import plugins
- UTC format date strings in select menus for consistency (was relative date formatting)
- Don't populate the fzf search with `--search`, it's already filtered. Separated `--query` from `--search` if you do want to populate the query string in addition to `--search` filtering
- When showing relative dates, don't include the year if the date is the previous year but a later month than the current month (less than a year old)
- When using `--editor` while adding an entry, include any note specified on the command line or via `--ask` for further editing

### 2.1.13

#### NEW

- `--val` flag for all display commands, allows tag value queries. Tag values are contained in parenthesis after the tag, e.g. @progress(50). Queries look like `--val "done < two weeks ago"`, "project *= oracle" or "progress >= 50". Wildcards allowed in value, comparators can be <, >, <=, >=, ==, *= (contains), ^= (begins with), $= (ends with). Numeric and date comparisons are detected automatically. Text comparisons are case insensitive. `--val` can be used multiple times in a command and you can use `--bool` to specify AND, OR, or NOT (default AND)
- `doing tag` now accepts a `--value` flag to define a value for a single tag, e.g. @tag(value)

#### FIXED

- `doing last --editor` errors

### 2.1.12

#### NEW

- Tag_dir command creates/updates .doingrc files in the current directory with default_tags values. Then all entries created within that directory (or subdirs) get tagged with that value.
- Synonym triggers allow `*` and `?` wildcards
- Add `--delete` flag for `doing last` to delete last entry
- `--delete` and `--editor` flags for `doing search`, batch edit and delete
- Example hook to add new entries containing a certain tag to Day One
- New hooks: pre_entry_add, post_entry_added, post_entry_updated, post_entry_removed, pre_export

#### IMPROVED

- If you need to use a colon in an autotag transform pattern, you can split with double colon, e.g. pattern::replacement
- Arrays defined in local configurations merge with main config instead of overwriting

#### FIXED

- `doing tags --interactive` wasn't showing menu

### 2.1.10

#### NEW

- `--age` (oldest|newest) option for view command

### 2.1.9

#### IMPROVED

- Only attempt to install fzf if it doesn't exist on the system. In case of errors, this means a user can manually install fzf and still be able to access `--interactive` options

#### FIXED

- Rotate command only archiving half of requested items
- Frozen string error in doing import plugin

### 2.1.8

#### NEW

- Hidden command `doing commands_accepting` which shows all commands that accept a given option, e.g. `doing commands_accepting search` shows all commands that take a search filter
- Hidden command `doing changelog` which outputs a paginated, formatted version of the change history.

#### IMPROVED

- The output of `doing template --list` now shows the file type of each template
- Output templates can now be saved to a default location/filename using `doing template html --save`

#### FIXED

- Error running `doing recent` on certain older ruby versions

### 2.1.6

#### NEW

- `doing redo` undoes a redo
- `doing undo -i` offers a list of available versions for selection
- Multiple undo. Every time a command modifies the doing file, a backup is written. Running `doing undo` repeatedly steps back through history, `doing undo 5` jumps back 5 versions
- When resetting via `doing select`, prompt for a date string
- `doing reset` accepts a date string argument to use as start date instead of current time if provided
- `doing tags` lists tags used in any/all sections, sortable, with or without frequency counts
- `doing show --menu` offers an interactive menu for selecting section and tag filters
- All commands that accept a `--tag` filter can now handle wildcards in the tag names. * to match any number of characters, ? to match a single character.
- New boolean type for tag searches, PATTERN (which is now the default). Combine tags using symbols to create more complex boolean searches, e.g. "doing +coding -work"
- You can now define `date_tags` in config, an array of tags/patterns that will be recognized when parsing for natural language dates which are converted when saving new entries
- `--search` strings can contain quoted phrases and use +/- to require or ban terms, e.g. `--search 'doing +coding -writing'
- Interactive option for redo command
- Plugins for Day One export

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump
- Matching algorithm can be configured in settings
- All template placeholders can now use the "printf" formatting that %title and %note have, allowing for padding, prefixes, etc.
- Move default locations for doing file and backups to ~/.local/share/doing
- `doing show --menu` will only offer tags that exist after any tag/search filters have been run
- `doing show @tag` with `--menu` will first filter by the @tag, then do an OR search for tags selected from the menu

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed
- Preserve colors when wrapping text to new lines
- Tag highlighting errors
- Template options specified in views were being overriden by options in templates. View config now has precedence, but will fall back to template config for missing keys

#### IMPROVED

- Better diff output for fzf preview of `doing undo` history
- Fall back to good ol' sed for colorizing diffs when no good tool is available
- `doing redo` (a.k.a. `doing undo --redo`) can be run multiple times, stepping forward through undo history. Can also take a count to jump

#### FIXED

- `doing reset` without filter not automatically affecting most recent entry
- `config set` now preserves value type (string, array, mapping) of previous value, coercing new value if needed

### 2.1.3

#### NEW

- BREAKING CHANGE: custom classes for Section (hash) and Items (Array). @content is still a regular Hash. Sections have methods :original and :items. This will affect plugins as wwid.content[section][:items] is now wwid[section].items (same for :original)
- `doing config set -r key.path` will delete a key from any config file, removing empty parent keys
- `config list` will list detected .doingrc files and the main config file in order of precedence - refactoring
- When modifying start dates or @done dates via an editor command, natural language strings can be used and will be parsed into doing-formatted dates automatically
- When editor is invoked, entry titles include start date, which can be modified
- `--before`, `--after`, and `--from` date filters for select command
- `--from` flag for `doing today` and `doing yesterday`, filter by time range
- `--from` flag for `doing search`, filter by date/time range
- Commands that accept `--before`, `--after`, and `--from` can now filter on time ranges. If the date string given contains only a time (no day or date), it will be interpreted as a time range, meaning the date isn't filtered, but only entries within the time range are shown/processed
- Add %duration placeholder to template variables
- Add `interval_format` setting to config (applies to root or any view/template) to set intervals/durations to human (2h 15m) or text (00:02:15)
- Add `duration` key to config (root or view/template). If set to true, will display durations by default (no need for `--duration`)
- Most display commands now have a `--duration` flag that will display an elapsed time if the entry is not marked @done

#### IMPROVED

- Config -o raw outputs value as YAML if result is a Hash/mapping, unquoted string if a single value, comma-separated list if it's an Array.
- Config -o json no longer includes key, only value.
- System agnostic method for checking available executables (pager, editor)
- Using `config set` and selecting a local config will no longer write the entire config to the local .doingrc. Instead, a nested path to the particular setting will be added to the config file.
- Config set will create missing keys. Fuzzy matching will work until the path fails, then path elements after that point will be added as verbatim keys to the specified configuration (with confirmation)
- Make menus only as tall as needed, so 5 options don't take up the whole screen
- Better word wrap for long note lines

#### FIXED

- `finish --took 60m` is supposed to backdate the start date if needed to finish at the current time and maintain an elapsed time
- If an editor was specified for config (or default as fallback) with command line options (e.g. `emacs -nw`), Doing would fail to recognize that the executable was available.

### 2.0.25

#### NEW

- `doing config set` to set single config values from command line
- BREAKING CHANGE: Moves ~/.doingrc to ~/.config/doing/config.yml
- BREAKING CHANGE: convert config flags to subcommands, e.g. `doing config --udpate` => `doing config update`, and `doing config --dump` => `doing config dump`

### 2.0.24

- include fzf source directly, in case git isn't installed
- fall back to installing fzf with sudo on error

### 2.0.20

#### IMPROVED

- completion script generator refactor and progress bars

#### FIXED

- compile fzf for current operating system

### 2.0.19

#### FIXED

- Remove any coloring before writing to doing file

### 2.0.18

#### FIXED

- Escape codes being included in doing file

### 2.0.17

#### IMPROVED

- Improvements to %title formatting and wrapping

### 2.0.16

- Test release to validate git flow automation

### 2.0.13

#### FIXED

- Remove amatch gem dependency due to compatibility issues with Windows systems (also removes `--fuzzy` option from all search commands)

### 2.0.11

#### NEW

- Append `/r` to tag transforms to replace original tag

#### FIXED

- Autotag tag transform fixes

### 2.0.10

#### NEW

- Add 'timer_format' config with 'human' option for tag totals
- If `doing view` and `doing show` are confused, offer option to run the other command
- `doing completion` to generate shell completion scripts for zsh, bash, and fish
- `--search` and `--not` for cancel command
- `--case` flag for commands with `--search`. Can be (c)ase-sensitive, (i)nsensitive, or (s)mart (default smart, case insensitive unless search string contains uppercase letters)
- Add `--exact` flag to all commands with `--search` flag to force exact matching without requiring single quote prefix
- Add `--not` flag to all commands with filters (`--tag`, `--search`, `--before`, etc.) to negate the filter and return entries NOT matched

#### IMPROVED

- More command line feedback
- Error formatting and output
- Add subcommand completion for `doing help` in fish shell
- Logging and error handling

#### FIXED

- Zsh completion not outputting results
- Remove `--[no]` from non-negatable options
- `doing plugins -t export -c` not outputting columns
- View config not respecting tag_order setting
 
### 2.0.3.pre

#### NEW

- Import calendar events from Calendar.app on macOS
- `doing config --update` will add newly added config keys to your existing config file (handy with plugins that define their own config keys)
- Add %idnote template placeholder for "indented note" (entire note indented one tab)
- (loosely printf-esque) formatting options for `%note` template placeholder
- `--interactive` mode to act on results of `doing grep`
- Printf formatting for title and date
- Doing import plugin
- Plugins command to list plugins
- `--dump` option for `doing config` to output a key.path config key as JSON, YAML, or raw output
- `--no-color` global flag
- Log levels, with `--quiet` and `--verbose` global flags
- Convert CLI messaging to Logger-based system
- Use DOING_DEBUG, DOING_QUIET, or DOING_LOG_LEVEL environment variables to specify log levels before configuration is read
- Hooks, register plugins to run based on events
- --[no-]pager and paginate: config option to enable paging output
- Never_finish and never_time config options to prevent items matching tags/sections from ever receiving @done (never_finish) or @done timestamp (never_time) - More configuration refactoring

#### IMPROVED

- Timeline output formatting
- Major plugin architecture refactoring
- Fix regression where notes stored in doing file were outdented, breaking TaskPaper compatibility
- When accepting a date filter, allow end date to be in the future
- If an edited item has no changes, don't update/output notification - Don't start with query when using grep `--interactive`
- Select menu item formatting
- Output wrapping for terminal display
- Redirect warn to STDOUT when run with `--stdout`
- Fish autocomplete
- `--config_file` global flag deprected, now uses $DOING_CONFIG environment variable so that config overrides can be available before the initial configuration is run
- When `--stdout` or not a TTY, no color or output formatting
- Highlight tags when showing results. Because it looks nice.
- `--tag` and `--search` for `doing note`
- View/section fuzzy guessing
- Error reporting
- If `doing config` finds local doingrc files, offers a menu for editing
- More filtering options for `doing finish`
- Doing done accepts `--unfinished` flag to finish last entry not marked @done (instead of last entry)
- Doing done accepts `--note` flag to append a note when completing an entry

#### FIXED

- Multi-word unquoted arguments to add_section being truncated
- Show `--from` with date span
- Handling of arbitrary times in natural language dates
- Backward scope of since command with arbitrary times
- `doing rotate --keep` wasn't respecting keep value

### 1.0.93

#### FIXED

- Gemfile error

### 1.0.91

#### NEW

- "taskpaper" format available for all output options
- "markdown" format available for all output commands (GFM-style task list, customizable template)
- `--rename` option for tag command to replace tags
- `--regex` option for tag command, for `--remove` and `--rename`

### 1.0.90

#### IMPROVED

- doing finish `--auto` now pulls from all sections, not just the section of the target entry

#### FIXED

- Minor fix for shell command in doing select
- Fix for doing finish `--auto` when matched item is last in list

### 1.0.89

#### NEW

- Pretty print JSON output
- `--no-menu` option for select command to use `--query` as a filter and act on matching entries without displaying menu

### 1.0.88

#### IMPROVED

- Add `--before` and `--after` time search to yesterday command
- Add `--before` and `--after` date search to search/grep command
- Add `--tag_order` to yesterday command

### 1.0.87

#### IMPROVED

- Add leading spaces to make %shortdate align properly, at least for the last week
- Add `--tag`, `--bool`, and `--search` to view command
- Add `--before` and `--after` date search to view command
- Add `--before` and `--after` date search to show command
- Add `--before` and `--after` time search to today command
- Add `--search` filter to show command
- More alignment/formatting fixes for %shortdate

### 1.0.86

#### IMPROVED

- Add `count` config option for templates->recent

### 1.0.85

#### IMPROVED

- Add `--before` DATE_STRING to archive and rotate commands
- Only create on rotate file per day, merge new entries into existing file

#### FIXED

- Fix `--auto` for finish command

### 1.0.84

#### NEW

- `rotate` command for archiving entries to new file

#### FIXED

- Fixed current_section config key not being honored in some commands

### 1.0.83

#### FIXED

- Fixes for `doing view` options, additional config keys for views

### 1.0.82

#### FIXED

- Bugfixes

### 1.0.81

#### IMPROVED

- fzf menu improvements
- allow multiple selections `doing select` action menu

### 1.0.80

#### IMPROVED

- Convert all menus to fzf screens

### 1.0.79

#### IMPROVED

- Wildcard tag removal using `doing select -t "tag*" -r`
- fzf menu display polish

#### FIXED

#### FIXED

- Gem missing fzf

### 1.0.78

#### IMPROVED

- If no action is specified with select command, an interactive menu is
presented
- add output action select command with formatting and save options
- Don't link URLs in html output that don't have a protocol

### 1.0.76

#### IMPROVED

- Refine editing multiple selections (doing select)

### 1.0.74

#### NEW

- Add `--tag` and `--search` flags to tag command to tag all entries matching search terms
- Add since command, which is the same as `doing on tuesday to now` but `doing since tuesday` just feels more intuitive. 

### 1.0.73

#### FIXED

- Fix for timeline output

### 1.0.72

#### NEW

- Add `doing select` to show menu of all tasks, searchable with fuzzy matching and the ability to perform certain tasks on multiple selections.

### 1.0.71

#### FIXED

- Fix for template command not working at all

### 1.0.70

#### FIXED

- Fix for `doing done --took 30m` setting the wrong @done timestamp when completing previous item

### 1.0.69

#### IMPROVED

- Add `--unfinished` option to finish and cancel commands

### 1.0.68

#### FIXED

- Fix error in `doing show --sort` argument parsing

### 1.0.67

#### FIXED

- Gem packaging error

### 1.0.66

#### IMPROVED

- More flexible boolean specification, can be: all, and, any, or, not, or none

#### FIXED

- Fix for some long flags being interpreted as arrays instead of strings
- Fix for archive command not removing original entries from archived section

### 1.0.65

#### IMPROVED

- Prevent duplicates/overlapping entries when importing

### 1.0.64

#### NEW

- Initial import feature for Timing.app reports

### 1.0.63

#### IMPROVED

- If `doing done --took=X` results in completion date greater than current time, use current time as completion date and backdate the entry's timestamp to fit

### 1.0.62

#### FIXED

- `doing done` with `--took=` and without `--back=` should set end time to start date plus `--took` value

### 1.0.61

#### IMPROVED

- Add `--search` filter to `doing archive`

### 1.0.60

#### FIXED

- Default value for `doing again --bool` was ALL, should be AND

### 1.0.59

#### IMPROVED

- Improvements to `doing again --tag=` functionality

### 1.0.58

#### IMPROVED

- Finish previous task if `doing again` and not already completed

### 1.0.57

#### IMPROVED

- Unit tests

### 1.0.56

#### IMPROVED

- Tag command tests

#### FIXED

- Doing not reading per-directory .doingrc configs

### 1.0.55

#### NEW

- Added config_editor_app setting to config so you can have
- A parenthetical at the end of an entry title becomes an attached
- `--editor` flag for `doing last` to edit last entry
- `--tag=` flag to filter `doing last` by tag
- `--search=` to filter `doing last` by text/regex search
- `--search=` for `doing finish`, finish last X entries matching search
- Add `tags_color` as a primary config key to highlight @tags in displayed entries

#### IMPROVED

- Clean up command line help
- `--editor` improvements for all commands that use it

#### FIXED

- Doing finish `--took` throwing error
- Doing tag `--remove` was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date

#### IMPROVED

- Add `--no-color` option to view command
- Add `--tag` to show for compatibility

#### FIXED

- Error running finish without `--tag` flag
- `--archive` flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry

#### FIXED

- `--archive` flag on finish, done, and cancel causing error

### 1.0.49

#### FIXED

- Fix for missing date on @done tags

### 1.0.48

#### FIXED

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

#### IMPROVED

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

#### IMPROVED

- Code cleanup

### 1.0.45

#### IMPROVED

- Only execute run_after script if changes are written

### 1.0.44

#### IMPROVED

- Remove unnecessary console logging

### 1.0.43

#### NEW

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

#### FIXED

- Fix note indentation in doing file

### 1.0.41

#### FIXED

- Fix for repeated backreferences in tag transform

### 1.0.40

#### IMPROVED

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

#### NEW

- Tag transforms
- Option to sort tags by name in `--totals`

### 1.0.33

#### FIXED

- Gem dependency updates

### 1.0.30

#### FIXED

- Fix for array comparison error

### 1.0.29

#### FIXED

- Bugfixes

### 1.0.28

#### IMPROVED

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

#### IMPROVED

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

#### IMPROVED

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

#### IMPROVED

#### IMPROVED

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

#### IMPROVED

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

#### IMPROVED

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

#### IMPROVED

- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

#### FIXED

- Fix handling of "local" config files, allowing per-project configurations

### 1.0.21

#### NEW

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)

#### FIXED

- CSS fix

### 1.0.20

#### NEW

- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

#### IMPROVED

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS

### 1.0.19

#### IMPROVED

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

#### IMPROVED

- Loosened up the template color resetting a bit more

#### FIXED

- Fix `undefined method [] for nil class` error in `doing view`

### 1.0.17

#### NEW

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

#### FIXED

- Fixes overzealous color resetting

### 1.0.15

#### FIXED

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

#### IMPROVED

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

#### FIXED

- Fix gsub error in doing meanwhile

### 1.0.8pre

#### NEW

- added doing on command
- Added autotagging to tag command
- JSON output option to view commands
- date filtering, improved date language
- let view templates define output format (csv, json, html, template)

#### IMPROVED

- add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

#### IMPROVED

- Slightly fuzzier searching in the grep command
- cleaner exits, `only_timed` key for view configs
- making the note command append new notes better, and load existing notes in the editor if `-e` is called
- handle multiple tag input in `show` tag filter
- Global tag operations, better reporting

#### FIXED

- fix for `-v` option

### 1.0.4pre

#### IMPROVED

- Improved HTML output
- `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
- add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
- fix for 1.8.7 `Dir.home` issue
- version bump
- don't show tag totals with zero times
- zsh completion for doing
- HTML styling
- `--only_timed` option
- added zsh completion file to `README.md`
- add zsh completion file

### 1.0.3pre

#### IMPROVED

- `done` command: making `--took` modify start time if `--back` isn't specified
- Cleaned up time totals, improved HTML output
- fixes for `--back` and `--took` parsing
- Adding more complete terminal reporting to archive command

### 1.0.0pre

#### IMPROVED

- Skipped ahead in the version numbering. Because I don't care.
- Added a `note` command and `--note` flags for entry creation commands

### 0.2.6pre

#### IMPROVED

- `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
- Add tests for Darwin to hide OS X-only features on other systems
- `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
- `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
- Basic command line reporting
- `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
- `doing grep` for searching by text or regex

### 0.2.5

#### IMPROVED

- Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
- Add section label to archived tasks automatically, excepting `Currently` section
- Today outputs and backdate for finish
- HTML styling and fix for 1.8.7 HAML errors
- Look, HTML output! (`--output html`)
- Also, `--output csv`
- let doing `archive` function on all sections
- option to exclude date from _@done_,  
- output newlines in sections and views
- Flagging (`doing mark`)
- fix for view/section guess error
- Adding tag filtering to archive command (`doing archive \@done`)
- `doing yesterday`
- `doing done -r` to remove last doing tag (optionally from `-s Section`)
- Add `-f` flag to specify alternate doing file
- `meanwhile` command

### 0.2.1

#### IMPROVED

- CSV output for show command (`--csv`)
- HTML output for show command (`--output html`)
- fuzzy searching for all commands that specify a view. 
- In the terminal, you'll see "Assume you meant XXX" to show what match it found, but this is output to STDERR (and won't show up if you're redirecting the output or using it in GeekTool, etc.)
- `tags_color` in view config to highlight tags at the end of the lines. Can be set to any of the `%colors`.
- Basic time tracking. 
- `-t` on `show` and `view` will turn on time calculations
- Intervals between timestamps and dated _@done_ tags are calculated for each line, if the tag exists. 
- You must include a `%interval` token in the appropriate template for it to show
- _@start(date)_ tags can optionally be used to override the timestamp in the calculation
- Any other tags in the line have that line's total added to them
- Totals for tags can be displayed at the end of output with `--totals`


### 0.2.0

#### IMPROVED

- `doing done` without argument tags last entry done
- `-a` archives them
- `doing finish` or `doing finish X` marks last X entries done
- `-a` archives them
- `doing tag tag1 [tag2]` tags last entry or `-c X` entries
- `doing tag -r tag1 [tag2]` removes said tag(s)
- custom views additions
- custom views can include `tags` and `tags_bool`
- `tags` is a space-separated list of tags to filter the results by
- `tags_bool` defines `AND` (all tags must exist), `OR` (any tag exists), or `NONE` (none of the tags exist)
- `order` key (`asc` or `desc`) defines output sort order by date
- section key can be set to `All` to combine sections
- `doing show` updates
- accepts `all` as a section
- arguments following section name are tags to filter by
- `-b` sets boolean (`AND`, `OR`, `NONE`) or (`ALL`, `ANY`, `NONE`) (default `OR`/`ANY`)
- use `-c X` to limit results
- use `-s` to set sort order (`asc` or `desc`)
- use `-a` to set age (`newest` or `oldest`)
- fuzzy section guessing when specified section isn't found
- fuzzy view guessing for `doing view` command

### 0.1.9

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later` and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)
- `doing views` shows all available custom views
- `doing view` without a view name will let you choose a view from a menu
- `doing archive` fixed so that `-k X` works to keep `X` number of entries in the section

### 0.1.7

#### IMPROVED

- colors in templated output
- `open` command
- opens in the default app for file type
- `-a APPNAME` (`doing open -a TaskPaper`)
- `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
- save a tmp file and open it in an editor
- allows multi-line entries, anything after first line is considered a note
- assumed when no input is provided (`doing now`)

