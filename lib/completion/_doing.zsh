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
                  'choose:Select a section to display from a menu'
                  'colors:List available color variables for configuration templates and views'
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
                  'reset:Reset the start time of an entry'
                  'begin:Reset the start time of an entry'
                  'rotate:Move entries to archive file'
                  'sections:List sections'
                  'select:Display an interactive menu to perform operations'
                  'show:List all entries'
                  'since:List entries since a date'
                  'tag:Add tag(s) to last entry'
                  'template:Output HTML'
                  'test:Test Stuff'
                  'today:List entries from today'
                  'undo:Undo the last change to the Doing file'
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
                args=(  )
            ;;
            resume) 
                args=(  )
            ;;
            archive) 
                args=(  )
            ;;
            move) 
                args=(  )
            ;;
            autotag) 
                args=(  )
            ;;
            cancel) 
                args=(  )
            ;;
            choose) 
                args=(  )
            ;;
            colors) 
                args=(  )
            ;;
            completion) 
                args=(  )
            ;;
            config) 
                args=(  )
            ;;
            done) 
                args=(  )
            ;;
            did) 
                args=(  )
            ;;
            finish) 
                args=(  )
            ;;
            grep) 
                args=(  )
            ;;
            search) 
                args=(  )
            ;;
            help) 
                args=(  )
            ;;
            import) 
                args=(  )
            ;;
            last) 
                args=(  )
            ;;
            later) 
                args=(  )
            ;;
            mark) 
                args=(  )
            ;;
            flag) 
                args=(  )
            ;;
            meanwhile) 
                args=(  )
            ;;
            note) 
                args=(  )
            ;;
            now) 
                args=(  )
            ;;
            next) 
                args=(  )
            ;;
            on) 
                args=(  )
            ;;
            open) 
                args=(  )
            ;;
            plugins) 
                args=(  )
            ;;
            recent) 
                args=(  )
            ;;
            reset) 
                args=(  )
            ;;
            begin) 
                args=(  )
            ;;
            rotate) 
                args=(  )
            ;;
            sections) 
                args=(  )
            ;;
            select) 
                args=(  )
            ;;
            show) 
                args=(  )
            ;;
            since) 
                args=(  )
            ;;
            tag) 
                args=(  )
            ;;
            template) 
                args=(  )
            ;;
            test) 
                args=(  )
            ;;
            today) 
                args=(  )
            ;;
            undo) 
                args=(  )
            ;;
            view) 
                args=(  )
            ;;
            views) 
                args=(  )
            ;;
            wiki) 
                args=(  )
            ;;
            yesterday) 
                args=(  )
            ;;
    esac

    _arguments -s $args
}

