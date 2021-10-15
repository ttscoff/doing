# doing CLI

A CLI for a What Was I Doing system

*v1.0.90*

## Global Options

### `--config_file` arg

Use a specific configuration file

*Default Value:* `/Users/ttscoff/.doingrc`

### `-f` | `--doing_file` arg

Specify a different doing_file

### `--help`

Show this message

### `--[no-]notes`

Output notes if included in the template

### `--stdout`

Send results report to STDOUT instead of STDERR

### `--version`

Display the program version

### `-x`|`--[no-]noauto`

Exclude auto tags and default tags

## Commands

### `$ doing` <mark>`add_section`</mark> `SECTION_NAME`

*Add a new section to the "doing" file*

* * * * * *

### `$ doing` <mark>`again|resume`</mark> ``

*Repeat last entry as new entry*

#### Options

##### `--bool` BOOLEAN

Boolean used to combine multiple tags

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `--in` SECTION_NAME

Add new entry to section (default: same section as repeated entry)

##### `-n` | `--note` TEXT

Note

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `--search` QUERY

Repeat last entry matching search. Surround with
  slashes for regex (e.g. "/query/").

##### `--tag` TAG

Repeat last entry matching tags. Combine multiple tags with a comma.

* * * * * *

### `$ doing` <mark>`archive`</mark> `SECTION_NAME`

*Move entries between sections*

#### Options

##### `--before` DATE_STRING

Archive entries older than date
    (Flexible date format, e.g. 1/27/2021, 2020-07-19, or Monday 3pm)

##### `--bool` BOOLEAN

Tag boolean (AND|OR|NOT)

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-k` | `--keep` X

How many items to keep (ignored if archiving by tag or search)

*Must Match:* `(?-mix:^\d+$)`

##### `--search` QUERY

Search filter

##### `-t` | `--to` SECTION_NAME

Move entries to

*Default Value:* `Archive`

##### `--tag` TAG

Tag filter, combine multiple tags with a comma. Added for compatibility with other commands.

##### `--[no-]label`

Label moved items with @from(SECTION_NAME)

* * * * * *

### `$ doing` <mark>`cancel`</mark> `COUNT`

*End last X entries with no time tracked*

> Adds @done tag without datestamp so no elapsed time is recorded. Alias for `doing finish --no-date`.

#### Options

##### `--bool` BOOLEAN

Boolean (AND|OR|NOT) with which to combine multiple tag filters

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-s` | `--section` NAME

Section

##### `--tag` TAG

Cancel the last X entries containing TAG. Separate multiple tags with comma (--tag=tag1,tag2)

##### `-a`|`--archive`

Archive entries

##### `-u`|`--unfinished`

Cancel last entry (or entries) not already marked @done

* * * * * *

### `$ doing` <mark>`choose`</mark> ``

*Select a section to display from a menu*

* * * * * *

### `$ doing` <mark>`colors`</mark> ``

*List available color variables for configuration templates and views*

* * * * * *

### `$ doing` <mark>`config`</mark> ``

*Edit the configuration file*

#### Options

##### `-a` APP_NAME

Application to use

##### `-b` BUNDLE_ID

Application bundle id to use

##### `-e` | `--editor` EDITOR

Editor to use

##### `-x`

Use the config_editor_app defined in ~/.doingrc (Sublime Text)

* * * * * *

### `$ doing` <mark>`done|did`</mark> `ENTRY`

*Add a completed item with @done(date). No argument finishes last entry.*

#### Options

##### `--at` DATE_STRING

Set finish date to specific date/time (natural langauge parsed, e.g. --at=1:30pm).
  If used, ignores --back. Used with --took, backdates start date

##### `-b` | `--back` DATE_STRING

Backdate start date by interval [4pm|20m|2h|yesterday noon]

##### `-s` | `--section` NAME

Section

##### `-t` | `--took` INTERVAL

Set completion date to start date plus interval (XX[mhd] or HH:MM).
  If used without the --back option, the start date will be moved back to allow
  the completion date to be the current time.

##### `-a`|`--archive`

Immediately archive the entry

##### `--[no-]date`

Include date

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

##### `-r`|`--remove`

Remove @done tag

* * * * * *

### `$ doing` <mark>`finish`</mark> `COUNT`

*Mark last X entries as @done*

> Marks the last X entries with a @done tag and current date. Does not alter already completed entries.

#### Options

##### `--at` DATE_STRING

Set finish date to specific date/time (natural langauge parsed, e.g. --at=1:30pm). If used, ignores --back.

##### `-b` | `--back` DATE_STRING

Backdate completed date to date string [4pm|20m|2h|yesterday noon]

##### `--bool` BOOLEAN

Boolean (AND|OR|NOT) with which to combine multiple tag filters

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-s` | `--section` NAME

Section

##### `--search` QUERY

Finish the last X entries matching search filter, surround with slashes for regex (e.g. "/query.*/")

##### `-t` | `--took` INTERVAL

Set the completed date to the start date plus XX[hmd]

##### `--tag` TAG

Finish the last X entries containing TAG.
  Separate multiple tags with comma (--tag=tag1,tag2), combine with --bool

##### `-a`|`--archive`

Archive entries

##### `--auto`

Auto-generate finish dates from next entry's start time.
  Automatically generate completion dates 1 minute before next item (in any section) began.
  --auto overrides the --date and --back parameters.

##### `--[no-]date`

Include date

##### `-u`|`--unfinished`

Finish last entry (or entries) not already marked @done

* * * * * *

### `$ doing` <mark>`grep|search`</mark> `SEARCH_PATTERN`

*Search for entries*

> Search all sections (or limit to a single section) for entries matching text or regular expression. Normal strings are fuzzy matched.
> 
> To search with regular expressions, single quote the string and surround with slashes: `doing search '/\bm.*?x\b/'`

#### Options

##### `--after` DATE_STRING

Constrain search to entries newer than date

##### `--before` DATE_STRING

Constrain search to entries older than date

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `--only_timed`

Only show items with recorded time intervals

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show intervals with totals at the end of output

* * * * * *

### `$ doing` <mark>`help`</mark> `command`

*Shows a list of commands or help for one command*

> Gets help for the application or its commands. Can also list the commands in a way helpful to creating a bash-style completion function

#### Options

##### `-c`

List commands one per line, to assist with shell completion

* * * * * *

### `$ doing` <mark>`import`</mark> `PATH`

*Import entries from an external source*

> Imports entries from other sources. Currently only handles JSON reports exported from Timing.app.

#### Options

##### `--prefix` PREFIX

Prefix entries with

##### `-s` | `--section` NAME

Target section

##### `--tag` TAGS

Tag all imported entries

##### `--type` TYPE

Import type

*Default Value:* `timing`

##### `--[no-]autotag`

Autotag entries

##### `--[no-]overlap`

Allow entries that overlap existing times

* * * * * *

### `$ doing` <mark>`last`</mark> ``

*Show the last entry, optionally edit*

#### Options

##### `--bool` BOOLEAN

Tag boolean

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-s` | `--section` NAME

Specify a section

*Default Value:* `All`

##### `--search` QUERY

Search filter, surround with slashes for regex (/query/)

##### `--tag` TAG

Tag filter, combine multiple tags with a comma.

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

* * * * * *

### `$ doing` <mark>`later`</mark> `ENTRY`

*Add an item to the Later section*

#### Options

##### `-b` | `--back` DATE_STRING

Backdate start time to date string [4pm|20m|2h|yesterday noon]

##### `-n` | `--note` TEXT

Note

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

* * * * * *

### `$ doing` <mark>`mark|flag`</mark> ``

*Mark last entry as highlighted*

#### Options

##### `-s` | `--section` NAME

Section

##### `-r`|`--remove`

Remove mark

##### `-u`|`--unfinished`

Mark last entry not marked @done

* * * * * *

### `$ doing` <mark>`meanwhile`</mark> `ENTRY`

*Finish any running @meanwhile tasks and optionally create a new one*

#### Options

##### `-b` | `--back` DATE_STRING

Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]

##### `-n` | `--note` TEXT

Note

##### `-s` | `--section` NAME

Section

##### `-a`|`--[no-]archive`

Archive previous @meanwhile entry

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

* * * * * *

### `$ doing` <mark>`note`</mark> `NOTE_TEXT`

*Add a note to the last entry*

> If -r is provided with no other arguments, the last note is removed. If new content is specified through arguments or STDIN, any previous note will be replaced with the new one.
> 
>   Use -e to load the last entry in a text editor where you can append a note.

#### Options

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

##### `-r`|`--remove`

Replace/Remove last entry's note (default append)

* * * * * *

### `$ doing` <mark>`now|next`</mark> `ENTRY`

*Add an entry*

#### Options

##### `-b` | `--back` DATE_STRING

Backdate start time [4pm|20m|2h|yesterday noon]

##### `-n` | `--note` TEXT

Note

##### `-s` | `--section` NAME

Section

##### `-e`|`--editor`

Edit entry with /Users/ttscoff/scripts/editor.sh

##### `-f`|`--finish_last`

Timed entry, marks last entry in section as @done

* * * * * *

### `$ doing` <mark>`on`</mark> `DATE_STRING`

*List entries for a date*

> Date argument can be natural language. "thursday" would be interpreted as "last thursday,"
> and "2d" would be interpreted as "two days ago." If you use "to" or "through" between two dates,
> it will create a range.

#### Options

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show time totals at the end of output

* * * * * *

### `$ doing` <mark>`open`</mark> ``

*Open the "doing" file in an editor*

> `doing open` defaults to using the editor_app setting in /Users/ttscoff/.doingrc (Taskpaper)

#### Options

##### `-a` | `--app` APP_NAME

Open with app name

##### `-b` | `--bundle_id` BUNDLE_ID

Open with app bundle id

##### `-e`|`--editor`

Open with $EDITOR (/Users/ttscoff/scripts/editor.sh)

* * * * * *

### `$ doing` <mark>`recent`</mark> `COUNT`

*List recent entries*

#### Options

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show intervals with totals at the end of output

* * * * * *

### `$ doing` <mark>`rotate`</mark> ``

*Move entries to archive file*

#### Options

##### `--before` DATE_STRING

Rotate entries older than date
    (Flexible date format, e.g. 1/27/2021, 2020-07-19, or Monday 3pm)

##### `--bool` BOOLEAN

Tag boolean (AND|OR|NOT)

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-k` | `--keep` X

How many items to keep in each section (most recent)

*Must Match:* `(?-mix:^\d+$)`

##### `-s` | `--section` SECTION_NAME

Section to rotate

*Default Value:* `All`

##### `--search` QUERY

Search filter

##### `--tag` TAG

Tag filter, combine multiple tags with a comma. Added for compatibility with other commands.

* * * * * *

### `$ doing` <mark>`sections`</mark> ``

*List sections*

#### Options

##### `-c`|`--[no-]column`

List in single column

* * * * * *

### `$ doing` <mark>`select`</mark> ``

*Display an interactive menu to perform operations (requires fzf)*

> List all entries and select with typeahead fuzzy matching.
> 
> Multiple selections are allowed, hit tab to add the highlighted entry to the selection. Return processes the selected entries.

#### Options

##### `-m` | `--move` SECTION

Move selected items to section

##### `-o` | `--output` FORMAT

Output entries to format (doing|taskpaper|csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:doing|taskpaper|html|csv|json|template|timeline)$)`

##### `-q` | `--query` QUERY

Initial search query for filtering. Matching is fuzzy. For exact matching, start query with a single quote, e.g. `--query "'search"

##### `-s` | `--section` SECTION

Select from a specific section

##### `--save_to` FILE

Save selected entries to file using --output format

##### `-t` | `--tag` TAG

Tag selected entries

##### `-a`|`--archive`

Archive selected items

##### `-c`|`--cancel`

Cancel selected items (add @done without timestamp)

##### `-d`|`--delete`

Delete selected items

##### `-e`|`--editor`

Edit selected item(s)

##### `-f`|`--finish`

Add @done with current time to selected item(s)

##### `--flag`

Add flag to selected item(s)

##### `--force`

Perform action without confirmation.

##### `--[no-]menu`

Use --no-menu to skip the interactive menu. Use with --query to filter items and act on results automatically. Test with `--output doing` to preview matches.

##### `-r`|`--remove`

Reverse -c, -f, --flag, and -t (remove instead of adding)

* * * * * *

### `$ doing` <mark>`show`</mark> `[SECTION|@TAGS]`

*List all entries*

> The argument can be a section name, @tag(s) or both.
>   "pick" or "choose" as an argument will offer a section menu.

#### Options

##### `-a` | `--age` AGE

Age (oldest|newest)

*Default Value:* `newest`

##### `--after` DATE_STRING

View entries newer than date

##### `-b` | `--bool` BOOLEAN

Tag boolean (AND,OR,NOT)

*Default Value:* `OR`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `--before` DATE_STRING

View entries older than date

##### `-c` | `--count` MAX

Max count to show

*Default Value:* `0`

##### `-f` | `--from` DATE_OR_RANGE

Date range to show, or a single day to filter date on.
    Date range argument should be quoted. Date specifications can be natural language.
    To specify a range, use "to" or "through": `doing show --from "monday to friday"`

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--sort` ORDER

Sort order (asc/desc)

*Default Value:* `ASC`

*Must Match:* `(?i-mx:^[ad].*)`

##### `--search` QUERY

Search filter, surround with slashes for regex (/query/)

##### `--tag` TAG

Tag filter, combine multiple tags with a comma. Added for compatibility with other commands.

##### `--tag_order` DIRECTION

Tag sort direction (asc|desc)

*Must Match:* `(?i-mx:^(?:a(?:sc)?|d(?:esc)?)$)`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time))`

##### `--only_timed`

Only show items with recorded time intervals

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show intervals with totals at the end of output

* * * * * *

### `$ doing` <mark>`since`</mark> `DATE_STRING`

*List entries since a date*

> Date argument can be natural language and are always interpreted as being in the past. "thursday" would be interpreted as "last thursday,"
> and "2d" would be interpreted as "two days ago."

#### Options

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Section

*Default Value:* `All`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show time totals at the end of output

* * * * * *

### `$ doing` <mark>`tag`</mark> `TAG...`

*Add tag(s) to last entry*

#### Options

##### `--bool` BOOLEAN

Boolean (AND|OR|NOT) with which to combine multiple tag filters

*Default Value:* `AND`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `-c` | `--count` COUNT

How many recent entries to tag (0 for all)

*Default Value:* `1`

##### `-s` | `--section` SECTION_NAME

Section

*Default Value:* `All`

##### `--search` QUERY

Tag entries matching search filter, surround with slashes for regex (e.g. "/query.*/")

##### `--tag` TAG

Tag the last X entries containing TAG.
  Separate multiple tags with comma (--tag=tag1,tag2), combine with --bool

##### `-a`|`--autotag`

Autotag entries based on autotag configuration in ~/.doingrc

##### `-d`|`--date`

Include current date/time with tag

##### `--force`

Don't ask permission to tag all entries when count is 0

##### `-r`|`--remove`

Remove given tag(s)

##### `-u`|`--unfinished`

Tag last entry (or entries) not marked @done

* * * * * *

### `$ doing` <mark>`template`</mark> `TYPE`

*Output HTML and CSS templates for customization*

> Templates are printed to STDOUT for piping to a file.
>   Save them and use them in the configuration file under html_template.
> 
>   Example `doing template HAML > ~/styles/my_doing.haml`

* * * * * *

### `$ doing` <mark>`today`</mark> ``

*List entries from today*

#### Options

##### `--after` TIME_STRING

View entries after specified time (e.g. 8am, 12:30pm, 15:00)

##### `--before` TIME_STRING

View entries before specified time (e.g. 8am, 12:30pm, 15:00)

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Specify a section

*Default Value:* `All`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show time totals at the end of output

* * * * * *

### `$ doing` <mark>`undo`</mark> ``

*Undo the last change to the doing_file*

#### Options

##### `-f` | `--file` PATH

Specify alternate doing file

* * * * * *

### `$ doing` <mark>`view`</mark> `VIEW_NAME`

*Display a user-created view*

> Command line options override view configuration

#### Options

##### `--after` DATE_STRING

View entries newer than date

##### `-b` | `--bool` BOOLEAN

Tag boolean (AND,OR,NOT)

*Default Value:* `OR`

*Must Match:* `(?i-mx:and|all|any|or|not|none)`

##### `--before` DATE_STRING

View entries older than date

##### `-c` | `--count` COUNT

Count to display

*Must Match:* `(?-mix:^\d+$)`

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Section

##### `--search` QUERY

Search filter, surround with slashes for regex (/query/)

##### `--tag` TAG

Tag filter, combine multiple tags with a comma.

##### `--tag_order` DIRECTION

Tag sort direction (asc|desc)

*Must Match:* `(?i-mx:^(?:a(?:sc)?|d(?:esc)?)$)`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `--[no-]color`

Include colors in output

##### `--only_timed`

Only show items with recorded time intervals (override view settings)

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show intervals with totals at the end of output

* * * * * *

### `$ doing` <mark>`views`</mark> ``

*List available custom views*

#### Options

##### `-c`|`--[no-]column`

List in single column

* * * * * *

### `$ doing` <mark>`yesterday`</mark> ``

*List entries from yesterday*

#### Options

##### `--after` TIME_STRING

View entries after specified time (e.g. 8am, 12:30pm, 15:00)

##### `--before` TIME_STRING

View entries before specified time (e.g. 8am, 12:30pm, 15:00)

##### `-o` | `--output` FORMAT

Output to export format (csv|html|json|template|timeline)

*Must Match:* `(?i-mx:^(?:template|html|csv|json|timeline)$)`

##### `-s` | `--section` NAME

Specify a section

*Default Value:* `All`

##### `--tag_order` DIRECTION

Tag sort direction (asc|desc)

*Must Match:* `(?i-mx:^(?:a(?:sc)?|d(?:esc)?)$)`

##### `--tag_sort` KEY

Sort tags by (name|time)

*Default Value:* `name`

*Must Match:* `(?i-mx:^(?:name|time)$)`

##### `-t`|`--[no-]times`

Show time intervals on @done tasks

##### `--totals`

Show time totals at the end of output

* * * * * *

#### [Default Command] recent

Documentation generated 2021-10-15 05:03

