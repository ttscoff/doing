compdef _doing doing

function _doing() {
    local line state

    function _commands {
        local -a commands

        commands=(
                  'add_section:Add a new section to the "doing" file'
                  'again:Repeat last entry as new entry'
                  'resume:Repeat last entry as new entry'
                  'archive:Move entries between sections'
                  'move:Move entries between sections'
                  'autotag:Autotag last entry or filtered entries'
                  'cancel:End last X entries with no time tracked'
                  'changes:List recent changes in Doing'
                  'changelog:List recent changes in Doing'
                  'colors:List available color variables for configuration templates and views'
                  'commands:Enable and disable Doing commands'
                  'completion:Generate shell completion scripts'
                  'config:Edit the configuration file or output a value from it'
                  'done:Add a completed item with @done(date)'
                  'did:Add a completed item with @done(date)'
                  'finish:Mark last X entries as @done'
                  'grep:Search for entries'
                  'search:Search for entries'
                  'help:Shows a list of commands or help for one command'
                  'import:Import entries from an external source'
                  'last:Show the last entry'
                  'later:Add an item to the Later section'
                  'mark:Mark last entry as flagged'
                  'flag:Mark last entry as flagged'
                  'meanwhile:Finish any running @meanwhile tasks and optionally create a new one'
                  'note:Add a note to the last entry'
                  'now:Add an entry'
                  'next:Add an entry'
                  'on:List entries for a date'
                  'open:Open the "doing" file in an editor'
                  'plugins:List installed plugins'
                  'recent:List recent entries'
                  'redo:Redo an undo command'
                  'reset:Reset the start time of an entry'
                  'begin:Reset the start time of an entry'
                  'rotate:Move entries to archive file'
                  'sections:List sections'
                  'select:Display an interactive menu to perform operations'
                  'show:List all entries'
                  'since:List entries since a date'
                  'tag:Add tag(s) to last entry'
                  'tag_dir:Set the default tags for the current directory'
                  'tags:List all tags in the current Doing file'
                  'template:Output HTML'
                  'test:Test Stuff'
                  'today:List entries from today'
                  'undo:Undo the last X changes to the Doing file'
                  'view:Display a user-created view'
                  'views:List available custom views'
                  'wiki:Output a tag wiki'
                  'yesterday:List entries from yesterday'
        )
        _describe 'command' commands
    }

    _arguments -C             "1: :_commands"             "*::arg:->args"



    case $line[1] in
        add_section) 
                args=(  )
            ;;
            again) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-e,--editor}"[Edit entry with vim]" {-i,--interactive}"[Select item to resume from a menu of matching entries]" "(--in=)--in=}[Add new entry to section]" {-n,--note=}"[Include a note]" "(--not)--not}[Repeat items that *dont* match search/tag filterst* match search/tag filters]" {-s,--section=}"[Get last entry from a specific section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            resume) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-e,--editor}"[Edit entry with vim]" {-i,--interactive}"[Select item to resume from a menu of matching entries]" "(--in=)--in=}[Add new entry to section]" {-n,--note=}"[Include a note]" "(--not)--not}[Repeat items that *dont* match search/tag filterst* match search/tag filters]" {-s,--section=}"[Get last entry from a specific section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            archive) 
                args=( "(--after=)--after=}[Archive entries newer than date]" "(--before=)--before=}[Archive entries older than date]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--from=)--from=}[Date range]" {-k,--keep=}"[How many items to keep]" "(--label)--label}[Label moved items with @from(SECTION_NAME)]" "(--not)--not}[Archive items that *dont* match search/tag filterst* match search/tag filters]" "(--search=)--search=}[Filter entries using a search query]" {-t,--to=}"[Move entries to]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            move) 
                args=( "(--after=)--after=}[Archive entries newer than date]" "(--before=)--before=}[Archive entries older than date]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--from=)--from=}[Date range]" {-k,--keep=}"[How many items to keep]" "(--label)--label}[Label moved items with @from(SECTION_NAME)]" "(--not)--not}[Archive items that *dont* match search/tag filterst* match search/tag filters]" "(--search=)--search=}[Filter entries using a search query]" {-t,--to=}"[Move entries to]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            autotag) 
                args=( "(--bool=)--bool=}[Boolean]" {-c,--count=}"[How many recent entries to autotag]" "(--force)--force}[Dont ask permission to autotag all entries when count is 0t ask permission to autotag all entries when count is 0]" {-i,--interactive}"[Select item(s) to tag from a menu of matching entries]" {-s,--section=}"[Section]" "(--search=)--search=}[Autotag entries matching search filter]" "(--tag=)--tag=}[Autotag the last X entries containing TAG]" {-u,--unfinished}"[Autotag last entry]" )
            ;;
            cancel) 
                args=( {-a,--archive}"[Archive entries]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-i,--interactive}"[Select item(s) to cancel from a menu of matching entries]" "(--not)--not}[Cancel items that *dont* match search/tag filterst* match search/tag filters]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" {-u,--unfinished}"[Cancel last entry]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            changes) 
                args=( {-C,--changes}"[Only output changes]" {-a,--all}"[Display all versions]" {-l,--lookup=}"[Look up a specific version]" "(--markdown)--markdown}[Output raw Markdown]" {-s,--search=}"[Show changelogs matching search terms]" )
            ;;
            changelog) 
                args=( {-C,--changes}"[Only output changes]" {-a,--all}"[Display all versions]" {-l,--lookup=}"[Look up a specific version]" "(--markdown)--markdown}[Output raw Markdown]" {-s,--search=}"[Show changelogs matching search terms]" )
            ;;
            colors) 
                args=(  )
            ;;
            commands) 
                args=(  )
            ;;
            completion) 
                args=( {-f,--file=}"[File to write output to]" {-t,--type=}"[Shell to generate for]" )
            ;;
            config) 
                args=( {-d,--dump}"[DEPRECATED]" {-u,--update}"[DEPRECATED]" )
            ;;
            done) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" {-a,--archive}"[Immediately archive the entry]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--finished=)--finished=}[Set finish date to specific date/time]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" "(--date)--date}[Include date]" {-e,--editor}"[Edit entry with vim]" "(--from=)--from=}[Start and end times as a date/time range `doing done --from "1am to 8am"`]" {-n,--note=}"[Include a note]" {-r,--remove}"[Remove @done tag]" {-s,--section=}"[Section]" "(--for=)--for=}[Set completion date to start date plus interval]" {-u,--unfinished}"[Finish last entry not already marked @done]" )
            ;;
            did) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" {-a,--archive}"[Immediately archive the entry]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--finished=)--finished=}[Set finish date to specific date/time]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" "(--date)--date}[Include date]" {-e,--editor}"[Edit entry with vim]" "(--from=)--from=}[Start and end times as a date/time range `doing done --from "1am to 8am"`]" {-n,--note=}"[Include a note]" {-r,--remove}"[Remove @done tag]" {-s,--section=}"[Section]" "(--for=)--for=}[Set completion date to start date plus interval]" {-u,--unfinished}"[Finish last entry not already marked @done]" )
            ;;
            finish) 
                args=( {-a,--archive}"[Archive entries]" "(--finished=)--finished=}[Set finish date to specific date/time]" "(--auto)--auto}[Auto-generate finish dates from next entrys start times start time]" "(--started=)--started=}[Backdate completed date to date string [4pm|20m|2h|yesterday noon]]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--date)--date}[Include date]" {-i,--interactive}"[Select item(s) to finish from a menu of matching entries]" "(--not)--not}[Finish items that *dont* match search/tag filterst* match search/tag filters]" {-r,--remove}"[Remove @done tag]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--for=)--for=}[Set the completed date to the start date plus XX[hmd]]" "(--tag=)--tag=}[Filter entries by tag]" {-u,--unfinished}"[Finish last entry]" "(--update)--update}[Overwrite existing @done tag with new date]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            grep) 
                args=( "(--after=)--after=}[Search entries newer than date]" "(--before=)--before=}[Search entries older than date]" "(--bool=)--bool=}[Combine multiple tags or value queries using AND]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--config_template=)--config_template=}[Output using a template from configuration]" {-d,--delete}"[Delete matching entries]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" {-e,--editor}"[Edit matching entries with vim]" "(--from=)--from=}[Date range]" {-h,--hilite}"[Highlight search matches in output]" {-i,--interactive}"[Display an interactive menu of results to perform further operations]" "(--not)--not}[Show items that *dont* match search stringt* match search string]" {-o,--output=}"[Output to export format]" "(--only_timed)--only_timed}[Only show items with recorded time intervals]" {-s,--section=}"[Section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show intervals with totals at the end of output]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact string matching]" )
            ;;
            search) 
                args=( "(--after=)--after=}[Search entries newer than date]" "(--before=)--before=}[Search entries older than date]" "(--bool=)--bool=}[Combine multiple tags or value queries using AND]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--config_template=)--config_template=}[Output using a template from configuration]" {-d,--delete}"[Delete matching entries]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" {-e,--editor}"[Edit matching entries with vim]" "(--from=)--from=}[Date range]" {-h,--hilite}"[Highlight search matches in output]" {-i,--interactive}"[Display an interactive menu of results to perform further operations]" "(--not)--not}[Show items that *dont* match search stringt* match search string]" {-o,--output=}"[Output to export format]" "(--only_timed)--only_timed}[Only show items with recorded time intervals]" {-s,--section=}"[Section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show intervals with totals at the end of output]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact string matching]" )
            ;;
            help) 
                args=(  )
            ;;
            import) 
                args=( "(--after=)--after=}[Import entries newer than date]" "(--autotag)--autotag}[Autotag entries]" "(--before=)--before=}[Import entries older than date]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--from=)--from=}[Date range]" "(--not)--not}[Import items that *dont* match search/tag/date filterst* match search/tag/date filters]" "(--only_timed)--only_timed}[Only import items with recorded time intervals]" "(--overlap)--overlap}[Allow entries that overlap existing times]" "(--prefix=)--prefix=}[Prefix entries with]" {-s,--section=}"[Target section]" "(--search=)--search=}[Filter entries using a search query]" {-t,--tag=}"[Tag all imported entries]" "(--type=)--type=}[Import type]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            last) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--config_template=)--config_template=}[Output using a template from configuration]" {-d,--delete}"[Delete the last entry]" "(--duration)--duration}[Show elapsed time if entry is not tagged @done]" {-e,--editor}"[Edit entry with vim]" {-h,--hilite}"[Highlight search matches in output]" "(--not)--not}[Show items that *dont* match search/tag filterst* match search/tag filters]" {-s,--section=}"[Specify a section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            later) 
                args=( "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start time to date string [4pm|20m|2h|yesterday noon]]" {-e,--editor}"[Edit entry with vim]" {-n,--note=}"[Note]" )
            ;;
            mark) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--count=}"[How many recent entries to tag]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-d,--date}"[Include current date/time with tag]" "(--force)--force}[Dont ask permission to flag all entries when count is 0t ask permission to flag all entries when count is 0]" {-i,--interactive}"[Select item(s) to flag from a menu of matching entries]" "(--not)--not}[Flag items that *dont* match search/tag filterst* match search/tag filters]" {-r,--remove}"[Remove flag]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" {-u,--unfinished}"[Flag last entry]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            flag) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--count=}"[How many recent entries to tag]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-d,--date}"[Include current date/time with tag]" "(--force)--force}[Dont ask permission to flag all entries when count is 0t ask permission to flag all entries when count is 0]" {-i,--interactive}"[Select item(s) to flag from a menu of matching entries]" "(--not)--not}[Flag items that *dont* match search/tag filterst* match search/tag filters]" {-r,--remove}"[Remove flag]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" {-u,--unfinished}"[Flag last entry]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            meanwhile) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" {-a,--archive}"[Archive previous @meanwhile entry]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" {-e,--editor}"[Edit entry with vim]" {-n,--note=}"[Include a note]" {-s,--section=}"[Section]" )
            ;;
            note) 
                args=( "(--ask)--ask}[Prompt for note via multi-line input]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-e,--editor}"[Edit entry with vim]" {-i,--interactive}"[Select item for new note from a menu of matching entries]" "(--not)--not}[Note items that *dont* match search/tag filterst* match search/tag filters]" {-r,--remove}"[Replace/Remove last entrys notes note]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            now) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" {-e,--editor}"[Edit entry with vim]" {-f,--finish_last}"[Timed entry]" "(--from=)--from=}[Set a start and optionally end time as a date range]" {-n,--note=}"[Include a note]" {-s,--section=}"[Section]" )
            ;;
            next) 
                args=( {-X,--noauto}"[Exclude auto tags and default tags]" "(--ask)--ask}[Prompt for note via multi-line input]" "(--started=)--started=}[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]" {-e,--editor}"[Edit entry with vim]" {-f,--finish_last}"[Timed entry]" "(--from=)--from=}[Set a start and optionally end time as a date range]" {-n,--note=}"[Include a note]" {-s,--section=}"[Section]" )
            ;;
            on) 
                args=( "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" {-o,--output=}"[Output to export format]" {-s,--section=}"[Section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show time totals at the end of output]" )
            ;;
            open) 
                args=( {-a,--app=}"[Open with app name]" {-b,--bundle_id=}"[Open with app bundle id]" {-e,--editor=}"[Open with editor command]" )
            ;;
            plugins) 
                args=( {-c,--column}"[List in single column for completion]" {-t,--type=}"[List plugins of type]" )
            ;;
            recent) 
                args=( "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" {-i,--interactive}"[Select from a menu of matching entries to perform additional operations]" {-s,--section=}"[Section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show intervals with totals at the end of output]" )
            ;;
            redo) 
                args=( {-f,--file=}"[Specify alternate doing file]" {-i,--interactive}"[Select from an interactive menu]" )
            ;;
            reset) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-i,--interactive}"[Select from a menu of matching entries]" "(--not)--not}[Reset items that *dont* match search/tag filterst* match search/tag filters]" {-r,--resume}"[Resume entry]" {-s,--section=}"[Limit search to section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            begin) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-i,--interactive}"[Select from a menu of matching entries]" "(--not)--not}[Reset items that *dont* match search/tag filterst* match search/tag filters]" {-r,--resume}"[Resume entry]" {-s,--section=}"[Limit search to section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            rotate) 
                args=( "(--before=)--before=}[Rotate entries older than date]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-k,--keep=}"[How many items to keep in each section]" "(--not)--not}[Rotate items that *dont* match search/tag filterst* match search/tag filters]" {-s,--section=}"[Section to rotate]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            sections) 
                args=( {-c,--column}"[List in single column]" )
            ;;
            select) 
                args=( {-a,--archive}"[Archive selected items]" "(--after=)--after=}[Select entries newer than date]" "(--resume)--resume}[Copy selection as a new entry with current time and no @done tag]" "(--before=)--before=}[Select entries older than date]" {-c,--cancel}"[Cancel selected items]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-d,--delete}"[Delete selected items]" {-e,--editor}"[Edit selected item(s)]" {-f,--finish}"[Add @done with current time to selected item(s)]" "(--flag)--flag}[Add flag to selected item(s)]" "(--force)--force}[Perform action without confirmation]" "(--from=)--from=}[Date range]" {-m,--move=}"[Move selected items to section]" "(--menu)--menu}[Use --no-menu to skip the interactive menu]" "(--not)--not}[Select items that *dont* match search/tag filterst* match search/tag filters]" {-o,--output=}"[Output entries to format]" {-q,--query=}"[Initial search query for filtering]" {-r,--remove}"[Reverse -c]" {-s,--section=}"[Select from a specific section]" "(--save_to=)--save_to=}[Save selected entries to file using --output format]" "(--search=)--search=}[Filter entries using a search query]" {-t,--tag=}"[Tag selected entries]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            show) 
                args=( {-a,--age=}"[Age]" "(--after=)--after=}[Show entries newer than date]" "(--before=)--before=}[Show entries older than date]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--count=}"[Max count to show]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" "(--from=)--from=}[Date range]" {-h,--hilite}"[Highlight search matches in output]" {-i,--interactive}"[Select from a menu of matching entries to perform additional operations]" {-m,--menu}"[Select section or tag to display from a menu]" "(--not)--not}[Show items that *dont* match search/tag filterst* match search/tag filters]" {-o,--output=}"[Output to export format]" "(--only_timed)--only_timed}[Only show items with recorded time intervals]" {-s,--sort=}"[Sort order]" "(--search=)--search=}[Filter entries using a search query]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag=)--tag=}[Filter entries by tag]" "(--tag_order=)--tag_order=}[Tag sort direction]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show intervals with totals at the end of output]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            since) 
                args=( "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" {-o,--output=}"[Output to export format]" {-s,--section=}"[Section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show time totals at the end of output]" )
            ;;
            tag) 
                args=( {-a,--autotag}"[Autotag entries based on autotag configuration in ~/]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--count=}"[How many recent entries to tag]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-d,--date}"[Include current date/time with tag]" "(--force)--force}[Dont ask permission to tag all entries when count is 0t ask permission to tag all entries when count is 0]" {-i,--interactive}"[Select item(s) to tag from a menu of matching entries]" "(--not)--not}[Tag items that *dont* match search/tag filterst* match search/tag filters]" {-r,--remove}"[Remove given tag(s)]" "(--regex)--regex}[Interpret tag string as regular expression]" "(--rename=)--rename=}[Replace existing tag with tag argument]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--tag=)--tag=}[Filter entries by tag]" {-u,--unfinished}"[Tag last entry]" {-v,--value=}"[Include a value]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            tag_dir) 
                args=( {-r,--remove}"[Remove all default_tags from the local]" )
            ;;
            tags) 
                args=( "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--counts}"[Show count of occurrences]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" {-i,--interactive}"[Select items to scan from a menu of matching entries]" {-l,--line}"[Output in a single line with @ symbols]" "(--not)--not}[Show items that *dont* match search/tag filterst* match search/tag filters]" {-o,--order=}"[Sort order]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" "(--sort=)--sort=}[Sort by name or count]" "(--tag=)--tag=}[Filter entries by tag]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            template) 
                args=( {-c,--column}"[List in single column for completion]" {-l,--list}"[List all available templates]" {-p,--path=}"[Save template to alternate location]" {-s,--save}"[Save template to file instead of STDOUT]" )
            ;;
            test) 
                args=(  )
            ;;
            today) 
                args=( "(--after=)--after=}[View entries after specified time]" "(--before=)--before=}[View entries before specified time]" "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" "(--from=)--from=}[Time range to show `doing today --from "12pm to 4pm"`]" {-o,--output=}"[Output to export format]" {-s,--section=}"[Specify a section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show time totals at the end of output]" )
            ;;
            undo) 
                args=( {-f,--file=}"[Specify alternate doing file]" {-i,--interactive}"[Select from recent backups]" {-p,--prune=}"[Remove old backups]" {-r,--redo}"[Redo last undo]" )
            ;;
            view) 
                args=( "(--after=)--after=}[Show entries newer than date]" "(--age=)--age=}[Age]" "(--before=)--before=}[Show entries older than date]" "(--bool=)--bool=}[Boolean used to combine multiple tags]" {-c,--count=}"[Count to display]" "(--case=)--case=}[Case sensitivity for search string matching [(c)ase-sensitive]" "(--color)--color}[Include colors in output]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" "(--from=)--from=}[Date range]" {-h,--hilite}"[Highlight search matches in output]" {-i,--interactive}"[Select from a menu of matching entries to perform additional operations]" "(--not)--not}[Show items that *dont* match search/tag filterst* match search/tag filters]" {-o,--output=}"[Output to export format]" "(--only_timed)--only_timed}[Only show items with recorded time intervals]" {-s,--section=}"[Section]" "(--search=)--search=}[Filter entries using a search query]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag=)--tag=}[Filter entries by tag]" "(--tag_order=)--tag_order=}[Tag sort direction]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--totals)--totals}[Show intervals with totals at the end of output]" "(--val=)--val=}[Perform a tag value query]" {-x,--exact}"[Force exact search string matching]" )
            ;;
            views) 
                args=( {-c,--column}"[List in single column]" )
            ;;
            wiki) 
                args=( "(--after=)--after=}[Include entries newer than date]" {-b,--bool=}"[Tag boolean]" "(--before=)--before=}[Include entries older than date]" {-f,--from=}"[Date range to include]" "(--only_timed)--only_timed}[Only show items with recorded time intervals]" {-s,--section=}"[Section to rotate]" "(--search=)--search=}[Search filter]" "(--tag=)--tag=}[Tag filter]" )
            ;;
            yesterday) 
                args=( "(--after=)--after=}[View entries after specified time]" "(--before=)--before=}[View entries before specified time]" "(--config_template=)--config_template=}[Output using a template from configuration]" "(--duration)--duration}[Show elapsed time on entries without @done tag]" "(--from=)--from=}[Time range to show]" {-o,--output=}"[Output to export format]" {-s,--section=}"[Specify a section]" {-t,--times}"[Show time intervals on @done tasks]" "(--tag_order=)--tag_order=}[Tag sort direction]" "(--tag_sort=)--tag_sort=}[Sort tags by]" "(--template=)--template=}[Override output format with a template string containing %placeholders]" "(--totals)--totals}[Show time totals at the end of output]" )
            ;;
    esac

    _arguments -s $args
}

