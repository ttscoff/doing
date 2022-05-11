compdef _doing doing

function _doing() {
    local line state

    function _commands {
        local -a commands

        commands=(
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
                  'completion:Generate shell completion scripts for doing'
                  'config:Edit the configuration file or output a value from it'
                  'done:Add a completed item with @done(date)'
                  'did:Add a completed item with @done(date)'
                  'finish:Mark last X entries as @done'
                  'grep:Search for entries'
                  'search:Search for entries'
                  'help:Shows a list of commands or help for one command'
                  'import:Import entries from an external source'
                  'last:Show the last entry'
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
                  'sections:List'
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
        again) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" "--ask[Prompt for note via multi-line input]" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--interactive)-i','(-i)--interactive'}"[Select item to resume from a menu of matching entries]" "--in[Add new entry to section]:SECTION_NAME:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" "--not[Repeat items that *don't* match search/tag filters]" {'(--section)-s','(-s)--section'}"[Get last entry from a specific section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            resume) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" "--ask[Prompt for note via multi-line input]" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--interactive)-i','(-i)--interactive'}"[Select item to resume from a menu of matching entries]" "--in[Add new entry to section]:SECTION_NAME:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" "--not[Repeat items that *don't* match search/tag filters]" {'(--section)-s','(-s)--section'}"[Get last entry from a specific section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            archive) 
                args=( "--after[Archive entries newer than date]:DATE_STRING:" "--before[Archive entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--from[Date range]:DATE_OR_RANGE:" {'(--keep)-k','(-k)--keep'}"[How many items to keep]:X:" "--label[Label moved items with @from(SECTION_NAME)]" "--not[Archive items that *don't* match search/tag filters]" "--search[Filter entries using a search query]:QUERY:" {'(--to)-t','(-t)--to'}"[Move entries to]:SECTION_NAME:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            move) 
                args=( "--after[Archive entries newer than date]:DATE_STRING:" "--before[Archive entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--from[Date range]:DATE_OR_RANGE:" {'(--keep)-k','(-k)--keep'}"[How many items to keep]:X:" "--label[Label moved items with @from(SECTION_NAME)]" "--not[Archive items that *don't* match search/tag filters]" "--search[Filter entries using a search query]:QUERY:" {'(--to)-t','(-t)--to'}"[Move entries to]:SECTION_NAME:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            autotag) 
                args=( "--bool[Boolean]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[How many recent entries to autotag]:COUNT:" "--force[Don't ask permission to autotag all entries when count is 0]" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to tag from a menu of matching entries]" {'(--section)-s','(-s)--section'}"[Section]:SECTION_NAME:" "--search[Autotag entries matching search filter]:QUERY:" "--tag[Autotag the last X entries containing TAG]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Autotag last entry]" )
            ;;
            cancel) 
                args=( {'(--archive)-a','(-a)--archive'}"[Archive entries]" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to cancel from a menu of matching entries]" "--not[Cancel items that *don't* match search/tag filters]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Cancel last entry]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            changes) 
                args=( {'(--changes)-C','(-C)--changes'}"[Only output changes]" {'(--all)-a','(-a)--all'}"[Display all versions]" {'(--interactive)-i','(-i)--interactive'}"[Open changelog in interactive viewer]" {'(--lookup)-l','(-l)--lookup'}"[Look up a specific version]:VERSION:" "--markdown[Output raw Markdown]" "--only[Only show changes of type(s)]:TYPES:" {'(--prefix)-p','(-p)--prefix'}"[Include]" "--render[Force rendered output]" {'(--search)-s','(-s)--search'}"[Show changelogs matching search terms]:arg:" "--sort[Sort order]:ORDER:" )
            ;;
            changelog) 
                args=( {'(--changes)-C','(-C)--changes'}"[Only output changes]" {'(--all)-a','(-a)--all'}"[Display all versions]" {'(--interactive)-i','(-i)--interactive'}"[Open changelog in interactive viewer]" {'(--lookup)-l','(-l)--lookup'}"[Look up a specific version]:VERSION:" "--markdown[Output raw Markdown]" "--only[Only show changes of type(s)]:TYPES:" {'(--prefix)-p','(-p)--prefix'}"[Include]" "--render[Force rendered output]" {'(--search)-s','(-s)--search'}"[Show changelogs matching search terms]:arg:" "--sort[Sort order]:ORDER:" )
            ;;
            colors) 
                args=(  )
            ;;
            commands) 
                args=(  )
            ;;
            completion) 
                args=( {'(--type)-t','(-t)--type'}"[Deprecated]:arg:" )
            ;;
            config) 
                args=( {'(--dump)-d','(-d)--dump'}"[DEPRECATED]" {'(--update)-u','(-u)--update'}"[DEPRECATED]" )
            ;;
            done) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" {'(--archive)-a','(-a)--archive'}"[Immediately archive the entry]" "--ask[Prompt for note via multi-line input]" "--finished[Set finish date to specific date/time]:DATE_STRING:" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" "--date[Include date]" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" "--from[Start and end times as a date/time range `doing done --from \"1am to 8am\"`]:TIME_RANGE:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" {'(--remove)-r','(-r)--remove'}"[Remove @done tag]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--for[Set completion date to start date plus interval]:INTERVAL:" {'(--unfinished)-u','(-u)--unfinished'}"[Finish last entry not already marked @done]" )
            ;;
            did) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" {'(--archive)-a','(-a)--archive'}"[Immediately archive the entry]" "--ask[Prompt for note via multi-line input]" "--finished[Set finish date to specific date/time]:DATE_STRING:" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" "--date[Include date]" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" "--from[Start and end times as a date/time range `doing done --from \"1am to 8am\"`]:TIME_RANGE:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" {'(--remove)-r','(-r)--remove'}"[Remove @done tag]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--for[Set completion date to start date plus interval]:INTERVAL:" {'(--unfinished)-u','(-u)--unfinished'}"[Finish last entry not already marked @done]" )
            ;;
            finish) 
                args=( {'(--archive)-a','(-a)--archive'}"[Archive entries]" "--finished[Set finish date to specific date/time]:DATE_STRING:" "--auto[Auto-generate finish dates from next entry's start time]" "--started[Backdate completed date to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--date[Include date]" "--from[Start and end times as a date/time range `doing done --from \"1am to 8am\"`]:TIME_RANGE:" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to finish from a menu of matching entries]" "--not[Finish items that *don't* match search/tag filters]" {'(--remove)-r','(-r)--remove'}"[Remove @done tag]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--for[Set completion date to start date plus interval]:INTERVAL:" "--tag[Filter entries by tag]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Finish last entry]" "--update[Overwrite existing @done tag with new date]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            grep) 
                args=( "--after[Search entries newer than date]:DATE_STRING:" "--before[Search entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" {'(--delete)-d','(-d)--delete'}"[Delete matching entries]" "--duration[Show elapsed time on entries without @done tag]" {'(--editor)-e','(-e)--editor'}"[Edit matching entries with vim]" "--from[Date range]:DATE_OR_RANGE:" {'(--hilite)-h','(-h)--hilite'}"[Highlight search matches in output]" {'(--interactive)-i','(-i)--interactive'}"[Display an interactive menu of results to perform further operations]" "--not[Search items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact string matching]" )
            ;;
            search) 
                args=( "--after[Search entries newer than date]:DATE_STRING:" "--before[Search entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" {'(--delete)-d','(-d)--delete'}"[Delete matching entries]" "--duration[Show elapsed time on entries without @done tag]" {'(--editor)-e','(-e)--editor'}"[Edit matching entries with vim]" "--from[Date range]:DATE_OR_RANGE:" {'(--hilite)-h','(-h)--hilite'}"[Highlight search matches in output]" {'(--interactive)-i','(-i)--interactive'}"[Display an interactive menu of results to perform further operations]" "--not[Search items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact string matching]" )
            ;;
            help) 
                args=(  )
            ;;
            import) 
                args=( "--after[Import entries newer than date]:DATE_STRING:" "--autotag[Autotag entries]" "--before[Import entries older than date]:DATE_STRING:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--from[Date range]:DATE_OR_RANGE:" "--not[Import items that *don't* match search/tag/date filters]" "--only_timed[Only import items with recorded time intervals]" "--overlap[Allow entries that overlap existing times]" "--prefix[Prefix entries with]:PREFIX:" {'(--section)-s','(-s)--section'}"[Target section]:NAME:" "--search[Filter entries using a search query]:QUERY:" {'(--tag)-t','(-t)--tag'}"[Tag all imported entries]:TAGS:" "--type[Import type]:TYPE:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            last) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" {'(--delete)-d','(-d)--delete'}"[Delete the last entry]" "--duration[Show elapsed time if entry is not tagged @done]" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--hilite)-h','(-h)--hilite'}"[Highlight search matches in output]" "--not[Show items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" {'(--section)-s','(-s)--section'}"[Specify a section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            mark) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[How many recent entries to tag]:COUNT:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--date)-d','(-d)--date'}"[Include current date/time with tag]" "--force[Don't ask permission to flag all entries when count is 0]" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to flag from a menu of matching entries]" "--not[Flag items that *don't* match search/tag filters]" {'(--remove)-r','(-r)--remove'}"[Remove flag]" {'(--section)-s','(-s)--section'}"[Section]:SECTION_NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Flag last entry]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            flag) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[How many recent entries to tag]:COUNT:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--date)-d','(-d)--date'}"[Include current date/time with tag]" "--force[Don't ask permission to flag all entries when count is 0]" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to flag from a menu of matching entries]" "--not[Flag items that *don't* match search/tag filters]" {'(--remove)-r','(-r)--remove'}"[Remove flag]" {'(--section)-s','(-s)--section'}"[Section]:SECTION_NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Flag last entry]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            meanwhile) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" {'(--archive)-a','(-a)--archive'}"[Archive previous @meanwhile entry]" "--ask[Prompt for note via multi-line input]" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" {'(--section)-s','(-s)--section'}"[Section]:NAME:" )
            ;;
            note) 
                args=( "--ask[Prompt for note via multi-line input]" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--interactive)-i','(-i)--interactive'}"[Select item for new note from a menu of matching entries]" "--not[Note items that *don't* match search/tag filters]" {'(--remove)-r','(-r)--remove'}"[Replace/Remove last entry's note]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            now) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" "--ask[Prompt for note via multi-line input]" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--finish_last)-f','(-f)--finish_last'}"[Timed entry]" "--from[Set a start and optionally end time as a date range]:TIME_RANGE:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" {'(--section)-s','(-s)--section'}"[Section]:NAME:" )
            ;;
            next) 
                args=( {'(--noauto)-X','(-X)--noauto'}"[Exclude auto tags and default tags]" "--ask[Prompt for note via multi-line input]" "--started[Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]]:DATE_STRING:" {'(--editor)-e','(-e)--editor'}"[Edit entry with vim]" {'(--finish_last)-f','(-f)--finish_last'}"[Timed entry]" "--from[Set a start and optionally end time as a date range]:TIME_RANGE:" {'(--note)-n','(-n)--note'}"[Include a note]:TEXT:" {'(--section)-s','(-s)--section'}"[Section]:NAME:" )
            ;;
            on) 
                args=( "--after[View entries after specified time]:TIME_STRING:" "--before[View entries before specified time]:TIME_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" "--from[Time range to show `doing on --from \"12pm to 4pm\"`]:TIME_RANGE:" "--not[Show items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" "--search[Filter entries using a search query]:QUERY:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            open) 
                args=( {'(--app)-a','(-a)--app'}"[Open with app name]:APP_NAME:" {'(--bundle_id)-b','(-b)--bundle_id'}"[Open with app bundle id]:BUNDLE_ID:" {'(--editor)-e','(-e)--editor'}"[Open with editor command]:COMMAND:" )
            ;;
            plugins) 
                args=( {'(--column)-c','(-c)--column'}"[List in single column for completion]" {'(--type)-t','(-t)--type'}"[List plugins of type]:TYPE:" )
            ;;
            recent) 
                args=( "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" {'(--interactive)-i','(-i)--interactive'}"[Select from a menu of matching entries to perform additional operations]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" )
            ;;
            redo) 
                args=( {'(--file)-f','(-f)--file'}"[Specify alternate doing file]:PATH:" {'(--interactive)-i','(-i)--interactive'}"[Select from an interactive menu]" )
            ;;
            reset) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--from[Start and end times as a date/time range `doing done --from \"1am to 8am\"`]:TIME_RANGE:" {'(--interactive)-i','(-i)--interactive'}"[Select from a menu of matching entries]" "--not[Reset items that *don't* match search/tag filters]" {'(--resume)-r','(-r)--resume'}"[Resume entry]" {'(--section)-s','(-s)--section'}"[Limit search to section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--for[Set completion date to start date plus interval]:INTERVAL:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            begin) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--from[Start and end times as a date/time range `doing done --from \"1am to 8am\"`]:TIME_RANGE:" {'(--interactive)-i','(-i)--interactive'}"[Select from a menu of matching entries]" "--not[Reset items that *don't* match search/tag filters]" {'(--resume)-r','(-r)--resume'}"[Resume entry]" {'(--section)-s','(-s)--section'}"[Limit search to section]:NAME:" "--search[Filter entries using a search query]:QUERY:" "--for[Set completion date to start date plus interval]:INTERVAL:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            rotate) 
                args=( "--before[Rotate entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--keep)-k','(-k)--keep'}"[How many items to keep in each section]:X:" "--not[Rotate items that *don't* match search/tag filters]" {'(--section)-s','(-s)--section'}"[Section to rotate]:SECTION_NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            sections) 
                args=(  )
            ;;
            select) 
                args=( {'(--archive)-a','(-a)--archive'}"[Archive selected items]" "--after[Select entries newer than date]:DATE_STRING:" "--resume[Copy selection as a new entry with current time and no @done tag]" "--before[Select entries older than date]:DATE_STRING:" {'(--cancel)-c','(-c)--cancel'}"[Cancel selected items]" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--delete)-d','(-d)--delete'}"[Delete selected items]" {'(--editor)-e','(-e)--editor'}"[Edit selected item(s)]" {'(--finish)-f','(-f)--finish'}"[Add @done with current time to selected item(s)]" "--flag[Add flag to selected item(s)]" "--force[Perform action without confirmation]" "--from[Date range]:DATE_OR_RANGE:" {'(--move)-m','(-m)--move'}"[Move selected items to section]:SECTION:" "--menu[Use --no-menu to skip the interactive menu]" "--not[Select items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output entries to format]:FORMAT:" {'(--query)-q','(-q)--query'}"[Initial search query for filtering]:QUERY:" {'(--remove)-r','(-r)--remove'}"[Reverse -c]" {'(--section)-s','(-s)--section'}"[Select from a specific section]:SECTION:" "--save_to[Save selected entries to file using --output format]:FILE:" "--search[Filter entries using a search query]:QUERY:" {'(--tag)-t','(-t)--tag'}"[Tag selected entries]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            show) 
                args=( {'(--age)-a','(-a)--age'}"[Age]:AGE:" "--after[Show entries newer than date]:DATE_STRING:" "--before[Show entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[Max count to show]:MAX:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" {'(--editor)-e','(-e)--editor'}"[Edit matching entries with vim]" "--from[Date range]:DATE_OR_RANGE:" {'(--hilite)-h','(-h)--hilite'}"[Highlight search matches in output]" {'(--interactive)-i','(-i)--interactive'}"[Select from a menu of matching entries to perform additional operations]" {'(--menu)-m','(-m)--menu'}"[Select section or tag to display from a menu]" "--not[Show items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--sort)-s','(-s)--sort'}"[Sort order]:ORDER:" "--save[Save all current command line options as a new view]:VIEW_NAME:" "--search[Filter entries using a search query]:QUERY:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            since) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" "--not[Since items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" "--search[Filter entries using a search query]:QUERY:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            tag) 
                args=( {'(--autotag)-a','(-a)--autotag'}"[Autotag entries based on autotag configuration in ~/]" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[How many recent entries to tag]:COUNT:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--date)-d','(-d)--date'}"[Include current date/time with tag]" "--force[Don't ask permission to tag all entries when count is 0]" {'(--interactive)-i','(-i)--interactive'}"[Select item(s) to tag from a menu of matching entries]" "--not[Tag items that *don't* match search/tag filters]" {'(--remove)-r','(-r)--remove'}"[Remove given tag(s)]" "--regex[Interpret tag string as regular expression]" "--rename[Replace existing tag with tag argument]:ORIG_TAG:" {'(--section)-s','(-s)--section'}"[Section]:SECTION_NAME:" "--search[Filter entries using a search query]:QUERY:" "--tag[Filter entries by tag]:TAG:" {'(--unfinished)-u','(-u)--unfinished'}"[Tag last entry]" {'(--value)-v','(-v)--value'}"[Include a value]:VALUE:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            tag_dir) 
                args=( "--clear[Remove all default_tags from the local]" {'(--editor)-e','(-e)--editor'}"[Use default editor to edit tag list]" {'(--remove)-r','(-r)--remove'}"[Delete tag(s) from the current list]" )
            ;;
            tags) 
                args=( "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--counts)-c','(-c)--counts'}"[Show count of occurrences]" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" {'(--interactive)-i','(-i)--interactive'}"[Select items to scan from a menu of matching entries]" {'(--line)-l','(-l)--line'}"[Output in a single line with @ symbols]" "--not[Show items that *don't* match search/tag filters]" {'(--order)-o','(-o)--order'}"[Sort order]:ORDER:" {'(--section)-s','(-s)--section'}"[Section]:SECTION_NAME:" "--search[Filter entries using a search query]:QUERY:" "--sort[Sort by name or count]:SORT_ORDER:" "--tag[Filter entries by tag]:TAG:" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            template) 
                args=( {'(--column)-c','(-c)--column'}"[List in single column for completion]" {'(--list)-l','(-l)--list'}"[List all available templates]" {'(--path)-p','(-p)--path'}"[Save template to alternate location]:DIRECTORY:" {'(--save)-s','(-s)--save'}"[Save template to file instead of STDOUT]" )
            ;;
            test) 
                args=(  )
            ;;
            today) 
                args=( "--after[View entries after specified time]:TIME_STRING:" "--before[View entries before specified time]:TIME_STRING:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" "--from[Time range to show `doing today --from \"12pm to 4pm\"`]:TIME_RANGE:" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Specify a section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" )
            ;;
            undo) 
                args=( {'(--file)-f','(-f)--file'}"[Specify alternate doing file]:PATH:" {'(--interactive)-i','(-i)--interactive'}"[Select from recent backups]" {'(--prune)-p','(-p)--prune'}"[Remove old backups]:COUNT:" {'(--redo)-r','(-r)--redo'}"[Redo last undo]" )
            ;;
            view) 
                args=( "--after[Show entries newer than date]:DATE_STRING:" "--age[Age]:AGE:" "--before[Show entries older than date]:DATE_STRING:" "--bool[Boolean used to combine multiple tags]:BOOLEAN:" {'(--count)-c','(-c)--count'}"[Count to display]:COUNT:" "--case[Case sensitivity for search string matching [(c)ase-sensitive]:TYPE:" "--color[Include colors in output]" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" "--from[Date range]:DATE_OR_RANGE:" {'(--hilite)-h','(-h)--hilite'}"[Highlight search matches in output]" {'(--interactive)-i','(-i)--interactive'}"[Select from a menu of matching entries to perform additional operations]" "--not[Show items that *don't* match search/tag filters]" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section]:NAME:" "--search[Filter entries using a search query]:QUERY:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag[Filter entries by tag]:TAG:" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--totals[Show intervals with totals at the end of output]" "--val[Perform a tag value query]:QUERY:" {'(--exact)-x','(-x)--exact'}"[Force exact search string matching]" )
            ;;
            views) 
                args=( {'(--column)-c','(-c)--column'}"[List in single column]" {'(--editor)-e','(-e)--editor'}"[Open YAML for view in editor]" {'(--output)-o','(-o)--output'}"[Output/edit view in alternative format]:FORMAT:" {'(--remove)-r','(-r)--remove'}"[Delete view config]" )
            ;;
            wiki) 
                args=( "--after[Include entries newer than date]:DATE_STRING:" {'(--bool)-b','(-b)--bool'}"[Tag boolean]:BOOLEAN:" "--before[Include entries older than date]:DATE_STRING:" {'(--from)-f','(-f)--from'}"[Date range to include]:DATE_OR_RANGE:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Section to rotate]:SECTION_NAME:" "--search[Search filter]:QUERY:" "--tag[Tag filter]:TAG:" )
            ;;
            yesterday) 
                args=( "--after[View entries after specified time]:TIME_STRING:" "--before[View entries before specified time]:TIME_STRING:" "--config_template[Output using a template from configuration]:TEMPLATE_KEY:" "--duration[Show elapsed time on entries without @done tag]" "--from[Time range to show `doing yesterday --from \"12pm to 4pm\"`]:TIME_RANGE:" {'(--output)-o','(-o)--output'}"[Output to export format]:FORMAT:" "--only_timed[Only show items with recorded time intervals]" {'(--section)-s','(-s)--section'}"[Specify a section]:NAME:" "--save[Save all current command line options as a new view]:VIEW_NAME:" {'(--times)-t','(-t)--times'}"[Show time intervals on @done tasks]" "--tag_order[Tag sort direction]:DIRECTION:" "--tag_sort[Sort tags by]:KEY:" "--template[Override output format with a template string containing %placeholders]:TEMPLATE_STRING:" "--title[Title string to be used for output formats that require it]:TITLE:" "--totals[Show time totals at the end of output]" )
            ;;
    esac

    _arguments -s $args
}

