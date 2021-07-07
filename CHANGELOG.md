### 1.0.61

- Add --search filter to `doing archive`

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
- --editor improvements for all commands that use it

#### FIXED

- Doing finish --took throwing error
- Doing tag --remove was adding tags if they didn't exist
- Creating a meanwhile task with a note resulted in an error

### 1.0.54

#### FIXED

- Bugfix for `finish --tag=TAG`

### 1.0.53

#### NEW

- `--tag` and `--bool` filtering for again/resume, cancel
- `--in` flag for `again`/`resume` to specify to which section the new
- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date (alias for

#### IMPROVED

- Add --no-color option to view command
- Add --tag to show for compatibility

#### FIXED

- Error running finish without --tag flag
- --archive flag on finish, done, and cancel causing error

### 1.0.52

#### NEW

- Finish command accepts `--tag=` flag, finishing last entry
- `doing cancel` to end X tasks without completion date (alias for

#### FIXED

- --archive flag on finish, done, and cancel causing error

### 1.0.49

- Fix for missing date on @done tags

### 1.0.48

- Fix confirmation dialog for `doing tag -a -c 0` (autotag all)

### 1.0.47

- Remove check for file existence before attempting to run run_after script
- Don't autotag entries restarted with `again/resume`
- Add short flags (`-b`) for `--back` on all commands that support it

### 1.0.46

- Code cleanup

### 1.0.45

- Only execute run_after script if changes are written

### 1.0.44

- Remove unneccessary console logging

### 1.0.43

- Add `again` command to repeat last entry without @done tag
- Add `run_after` configuration option to execute external script after any change

### 1.0.42

- Fix note indentation in doing file

### 1.0.41

- Fix for repeated backreferences in tag transform

### 1.0.40

- Add `--tag_sort` to all subcommands with `--totals` option

### 1.0.39

- Tag transforms
- Option to sort tags by name in --totals

### 1.0.33

- Gem dependency updates

### 1.0.30

- Fix for array comparison error

### 1.0.29

- Bugfixes

### 1.0.28

- Global option `-x` to skip autotags and default_tags from global/local .doingrc
- Remove extra spaces when creating entry

### 1.0.27

- More graceful writing of default config (~/.doingrc) on first run
- Repaired testing setup. Needs moar tests.

### 1.0.26

- Add `--at` flag for `doing done`, e.g. `doing done --at=1:35pm --took=15m A new task I already finished`
- Allow decimal quantities when using natural language for hours or days, e.g. `--took=2.5h`
- Add `did` as a synonym for `done` subcommand

### 1.0.25

- Smarter method of getting user $HOME
- Improved avoiding duplicate tags when autotagging
- Improved autotag reporting

### 1.0.24

- `doing note` operates on whatever is most recent, not just the last note in Currently
- `doing tag` with no count specified operates on most recent entry in any section, not just Currently
- `doing tag` with a count greater than 1 requires a section to be specified
- Improved results reporting for `doing tag`
- When removing tag do a whole-word match to avoid removing part of a longer tag

### 1.0.23

- Apply default_tags after autotagging to avoid tags triggering tags
- Set `doing recent` to default to All sections instead of Currently
- Fix error in time reporting
- improved y/n prompt for TTY

### 1.0.22

- Fix handling of "local" config files, allowing per-project configurations
- Allow cascading of local config files
- Allow `doing today` and `yesterday` to specify a section

### 1.0.21

- Add legitimate regex search capabilities
- Synonyms for grep (search) and now (next)
- CSS fix

### 1.0.20

- Rewrite HTML export templates with responsive layout and typography
- Ability to customize the HTML output using HAML and CSS
- New command `doing templates` to export default templates for HAML and CSS
- New config options under `html_template` for `haml` and `css`

### 1.0.19

- For `doing note -e` include the entry title so you know what you're adding a note to
- For any other command that allows `-e` include a comment noting that anything after the first line creates a note
- Ignore # comments when parsing editor results
- Add a .md extension to the temp file passed to the editor so you can take advantage of any syntax highlighting and other features in your editor

### 1.0.18

- Fix `undefined method [] for nil class` error in `doing view`
- Loosened up the template color resetting a bit more

### 1.0.17

- Add `--stdout` global option to send reporting to STDOUT instead of STDERR (for use with LaunchBar et al)

### 1.0.16

- Fixes overzealous color resetting

### 1.0.15

- CLI/text totals block was outputting when HTML output was selected
- Have all template colors reset bold and background automatically when called

### 1.0.14

Catching up on the changelog. Kind of. A lot has happened, mostly fixes.

- Fish completion
- views and sections subcommands have -c option to output single column
- Fix html title when tag_bool is NONE
- Fix @from tagging missing closing paren
- Fix tag coloring

### 1.0.13

- Fix gsub error in doing meanwhile

### 1.0.8pre

* JSON output option to view commands
* Added autotagging to tag command
* date filtering, improved date language
* added doing on command
* let view templates define output format (csv, json, html, template)
    * add `%chompnote` template variable (item note with newlines and extra whitespace stripped)

### 1.0.7pre

* fix for `-v` option
* Slightly fuzzier searching in the grep command
* cleaner exits, `only_timed` key for view configs
* making the note command append new notes better, and load existing notes in the editor if `-e` is called
* handle multiple tag input in `show` tag filter
* Global tag operations, better reporting

### 1.0.4pre

* Improved HTML output
* `--only_timed` option for view/show commands that only outputs items with elapsed timers (interval between start and done dates)
* add seconds for timed items in CSV output, run `--only_timed` before chopping off `--count #`
* fix for 1.8.7 `Dir.home` issue
* version bump
* don't show tag totals with zero times
* zsh completion for doing
* HTML styling
* `--only_timed` option
* added zsh completion file to `README.md`
* add zsh completion file

### 1.0.3pre

* `done` command: making `--took` modify start time if `--back` isn't specified
* Cleaned up time totals, improved HTML output
* fixes for `--back` and `--took` parsing
* Adding more complete terminal reporting to archive command

### 1.0.0pre

* Skipped ahead in the version numbering. Because I don't care.
* Added a `note` command and `--note` flags for entry creation commands

* * * 

### 0.2.6pre

* `--totals`, `--[no-]times`, `--output [csv,html]` options for `yesterday` command.
* Add tests for Darwin to hide OS X-only features on other systems
* `-f` flag to `now` command for finishing last task when starting a new one (Looks back for the last unfinished task in the list)
* `--took` option for `done` and `finish` for specifying intervals from the start date for the completion date
* Basic command line reporting
* `--auto` flag for `finish` and `done` that will automatically set the completion time to 1 minute before the next start time in the list. You can use it retroactively to add times to sequential todos.
* `doing grep` for searching by text or regex

### 0.2.5

* Default to showing times #26, show totals even if no tags exist #27, fix indentation #29
* Add section label to archived tasks automatically, excepting `Currently` section
* Today outputs and backdate for finish
* HTML styling and fix for 1.8.7 haml errors
* Look, HTML output! (`--output html`)
* Also, `--output csv`
* let doing `archive` function on all sections
* option to exclude date from _@done_,  
* output newlines in sections and views
* Flagging (`doing mark`)
* fix for view/section guess error
* Adding tag filtering to archive command (`doing archive \@done`)
* `doing yesterday`
* `doing done -r` to remove last doing tag (optionally from `-s Section`)
* Add `-f` flag to specify alternate doing file
* `meanwhile` command

### 0.2.1

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

* * *

### 0.1.9

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

- colors in templated output
- `open` command
  - opens in the default app for file type
  - `-a APPNAME` (`doing open -a TaskPaper`)
  - `-b bundle_id` (`doing open -b com.sublimetext.3`)
- `-e` switch for `now`, `later`, and `done` commands
  - save a tmp file and open it in an editor
  - allows multi-line entries, anything after first line is considered a note
  - assumed when no input is provided (`doing now`)

