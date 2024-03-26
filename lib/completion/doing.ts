const completionSpec: Fig.Spec = {
  name: "doing",
  description: "A CLI for a What Was I Doing system",
  subcommands: [
    {
      name: "again",
      description: "Repeat last entry as new entry",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item to resume from a menu of matching entries",
            
          },

          {
            name: ["--in"],
            description: "Add new entry to section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["--not"],
            description: "Repeat items that *don't* match search/tag filters",
            
          },

          {
            name: ["-s", "--section"],
            description: "Get last entry from a specific section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "resume",
      description: "Repeat last entry as new entry",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item to resume from a menu of matching entries",
            
          },

          {
            name: ["--in"],
            description: "Add new entry to section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["--not"],
            description: "Repeat items that *don't* match search/tag filters",
            
          },

          {
            name: ["-s", "--section"],
            description: "Get last entry from a specific section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "archive",
      description: "Move entries between sections",
      options: [
          {
            name: ["--after"],
            description: "Archive entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--before"],
            description: "Archive entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-k", "--keep"],
            description: "How many items to keep",
            args: {
                  name: "X",
                  description: "X",
            },

          },

          {
            name: ["--label"],
            description: "Label moved items with @from(SECTION_NAME)",
            
          },

          {
            name: ["--not"],
            description: "Archive items that *don't* match search/tag filters",
            
          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--to"],
            description: "Move entries to",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "move",
      description: "Move entries between sections",
      options: [
          {
            name: ["--after"],
            description: "Archive entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--before"],
            description: "Archive entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-k", "--keep"],
            description: "How many items to keep",
            args: {
                  name: "X",
                  description: "X",
            },

          },

          {
            name: ["--label"],
            description: "Label moved items with @from(SECTION_NAME)",
            
          },

          {
            name: ["--not"],
            description: "Archive items that *don't* match search/tag filters",
            
          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--to"],
            description: "Move entries to",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "autotag",
      description: "Autotag last entry or filtered entries",
      options: [
          {
            name: ["--bool"],
            description: "Boolean",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "How many recent entries to autotag",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["--force"],
            description: "Don't ask permission to autotag all entries when count is 0",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to tag from a menu of matching entries",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Autotag entries matching search filter",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Autotag the last X entries containing TAG",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Autotag last entry",
            
          },

        ],

    },

    {
      name: "cancel",
      description: "End last X entries with no time tracked",
      options: [
          {
            name: ["-a", "--archive"],
            description: "Archive entries",
            
          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to cancel from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Cancel items that *don't* match search/tag filters",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Cancel last entry",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "changes",
      description: "List recent changes in Doing",
      options: [
          {
            name: ["-C", "--changes"],
            description: "Only output changes",
            
          },

          {
            name: ["-a", "--all"],
            description: "Display all versions",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Open changelog in interactive viewer",
            
          },

          {
            name: ["-l", "--lookup"],
            description: "Look up a specific version",
            args: {
                  name: "VERSION",
                  description: "VERSION",
            },

          },

          {
            name: ["--markdown"],
            description: "Output raw Markdown",
            
          },

          {
            name: ["--only"],
            description: "Only show changes of type(s)",
            args: {
                  name: "TYPES",
                  description: "TYPES",
            },

          },

          {
            name: ["-p", "--prefix"],
            description: "Include",
            
          },

          {
            name: ["--render"],
            description: "Force rendered output",
            
          },

          {
            name: ["-s", "--search"],
            description: "Show changelogs matching search terms",
            args: {
                  name: "arg",
                  description: "arg",
            },

          },

          {
            name: ["--sort"],
            description: "Sort order",
            args: {
                  name: "ORDER",
                  description: "ORDER",
            },

          },

        ],

    },

    {
      name: "changelog",
      description: "List recent changes in Doing",
      options: [
          {
            name: ["-C", "--changes"],
            description: "Only output changes",
            
          },

          {
            name: ["-a", "--all"],
            description: "Display all versions",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Open changelog in interactive viewer",
            
          },

          {
            name: ["-l", "--lookup"],
            description: "Look up a specific version",
            args: {
                  name: "VERSION",
                  description: "VERSION",
            },

          },

          {
            name: ["--markdown"],
            description: "Output raw Markdown",
            
          },

          {
            name: ["--only"],
            description: "Only show changes of type(s)",
            args: {
                  name: "TYPES",
                  description: "TYPES",
            },

          },

          {
            name: ["-p", "--prefix"],
            description: "Include",
            
          },

          {
            name: ["--render"],
            description: "Force rendered output",
            
          },

          {
            name: ["-s", "--search"],
            description: "Show changelogs matching search terms",
            args: {
                  name: "arg",
                  description: "arg",
            },

          },

          {
            name: ["--sort"],
            description: "Sort order",
            args: {
                  name: "ORDER",
                  description: "ORDER",
            },

          },

        ],

    },

    {
      name: "colors",
      description: "List available color variables for configuration templates and views",
      
    },

    {
      name: "commands",
      description: "Enable and disable Doing commands",
      
    },

    {
      name: "completion",
      description: "Generate shell completion scripts for doing",
      options: [
          {
            name: ["-t", "--type"],
            description: "Deprecated",
            args: {
                  name: "arg",
                  description: "arg",
            },

          },

        ],

    },

    {
      name: "config",
      description: "Edit the configuration file or output a value from it",
      options: [
          {
            name: ["-d", "--dump"],
            description: "DEPRECATED",
            
          },

          {
            name: ["-u", "--update"],
            description: "DEPRECATED",
            
          },

        ],

    },

    {
      name: "done",
      description: "Add a completed item with @done(date)",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["-a", "--archive"],
            description: "Immediately archive the entry",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--finished"],
            description: "Set finish date to specific date/time",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--date"],
            description: "Include date",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["--from"],
            description: "Start and end times as a date/time range `doing done --from \"1am to 8am\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["-r", "--remove"],
            description: "Remove @done tag",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--for"],
            description: "Set completion date to start date plus interval",
            args: {
                  name: "INTERVAL",
                  description: "INTERVAL",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Finish last entry not already marked @done",
            
          },

        ],

    },

    {
      name: "did",
      description: "Add a completed item with @done(date)",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["-a", "--archive"],
            description: "Immediately archive the entry",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--finished"],
            description: "Set finish date to specific date/time",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--date"],
            description: "Include date",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["--from"],
            description: "Start and end times as a date/time range `doing done --from \"1am to 8am\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["-r", "--remove"],
            description: "Remove @done tag",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--for"],
            description: "Set completion date to start date plus interval",
            args: {
                  name: "INTERVAL",
                  description: "INTERVAL",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Finish last entry not already marked @done",
            
          },

        ],

    },

    {
      name: "finish",
      description: "Mark last X entries as @done",
      options: [
          {
            name: ["-a", "--archive"],
            description: "Archive entries",
            
          },

          {
            name: ["--finished"],
            description: "Set finish date to specific date/time",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--auto"],
            description: "Auto-generate finish dates from next entry's start time",
            
          },

          {
            name: ["--started"],
            description: "Backdate completed date to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--date"],
            description: "Include date",
            
          },

          {
            name: ["--from"],
            description: "Start and end times as a date/time range `doing done --from \"1am to 8am\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to finish from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Finish items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Remove @done tag",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--for"],
            description: "Set completion date to start date plus interval",
            args: {
                  name: "INTERVAL",
                  description: "INTERVAL",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Finish last entry",
            
          },

          {
            name: ["--update"],
            description: "Overwrite existing @done tag with new date",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "grep",
      description: "Search for entries",
      options: [
          {
            name: ["--after"],
            description: "Search entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--before"],
            description: "Search entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["-d", "--delete"],
            description: "Delete matching entries",
            
          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit matching entries with vim",
            
          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-h", "--hilite"],
            description: "Highlight search matches in output",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Display an interactive menu of results to perform further operations",
            
          },

          {
            name: ["--not"],
            description: "Search items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact string matching",
            
          },

        ],

    },

    {
      name: "search",
      description: "Search for entries",
      options: [
          {
            name: ["--after"],
            description: "Search entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--before"],
            description: "Search entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["-d", "--delete"],
            description: "Delete matching entries",
            
          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit matching entries with vim",
            
          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-h", "--hilite"],
            description: "Highlight search matches in output",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Display an interactive menu of results to perform further operations",
            
          },

          {
            name: ["--not"],
            description: "Search items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact string matching",
            
          },

        ],

    },

    {
      name: "help",
      description: "Shows a list of commands or help for one command",
      options: [
          
        ],

    },

    {
      name: "import",
      description: "Import entries from an external source",
      options: [
          {
            name: ["--after"],
            description: "Import entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--autotag"],
            description: "Autotag entries",
            
          },

          {
            name: ["--before"],
            description: "Import entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["--not"],
            description: "Import items that *don't* match search/tag/date filters",
            
          },

          {
            name: ["--only_timed"],
            description: "Only import items with recorded time intervals",
            
          },

          {
            name: ["--overlap"],
            description: "Allow entries that overlap existing times",
            
          },

          {
            name: ["--prefix"],
            description: "Prefix entries with",
            args: {
                  name: "PREFIX",
                  description: "PREFIX",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Target section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--tag"],
            description: "Tag all imported entries",
            args: {
                  name: "TAGS",
                  description: "TAGS",
            },

          },

          {
            name: ["--type"],
            description: "Import type",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "last",
      description: "Show the last entry",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["-d", "--delete"],
            description: "Delete the last entry",
            
          },

          {
            name: ["--duration"],
            description: "Show elapsed time if entry is not tagged @done",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-h", "--hilite"],
            description: "Highlight search matches in output",
            
          },

          {
            name: ["--not"],
            description: "Show items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Specify a section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "later",
      description: "Add an item to the Later section",
      options: [
          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--started"],
            description: "Backdate start time to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-n", "--note"],
            description: "Note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

        ],

    },

    {
      name: "mark",
      description: "Mark last entry as flagged",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "How many recent entries to tag",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-d", "--date"],
            description: "Include current date/time with tag",
            
          },

          {
            name: ["--force"],
            description: "Don't ask permission to flag all entries when count is 0",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to flag from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Flag items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Remove flag",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Flag last entry",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "flag",
      description: "Mark last entry as flagged",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "How many recent entries to tag",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-d", "--date"],
            description: "Include current date/time with tag",
            
          },

          {
            name: ["--force"],
            description: "Don't ask permission to flag all entries when count is 0",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to flag from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Flag items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Remove flag",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Flag last entry",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "meanwhile",
      description: "Finish any running @meanwhile tasks and optionally create a new one",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["-a", "--archive"],
            description: "Archive previous @meanwhile entry",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

        ],

    },

    {
      name: "note",
      description: "Add a note to the last entry",
      options: [
          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item for new note from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Note items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Replace/Remove last entry's note",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "now",
      description: "Add an entry",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-f", "--finish_last"],
            description: "Timed entry",
            
          },

          {
            name: ["--from"],
            description: "Set a start and optionally end time as a date range",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

        ],

    },

    {
      name: "next",
      description: "Add an entry",
      options: [
          {
            name: ["-X", "--noauto"],
            description: "Exclude auto tags and default tags",
            
          },

          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["--since"],
            description: "Backdate start date for new entry to date string [4pm|20m|2h|yesterday noon]",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-f", "--finish_last"],
            description: "Timed entry",
            
          },

          {
            name: ["--from"],
            description: "Set a start and optionally end time as a date range",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-n", "--note"],
            description: "Include a note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

        ],

    },

    {
      name: "on",
      description: "List entries for a date",
      options: [
          {
            name: ["--after"],
            description: "View entries after specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--before"],
            description: "View entries before specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["--from"],
            description: "Time range to show `doing on --from \"12pm to 4pm\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["--not"],
            description: "Show items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "open",
      description: "Open the \"doing\" file in an editor",
      options: [
          {
            name: ["-a", "--app"],
            description: "Open with app name",
            args: {
                  name: "APP_NAME",
                  description: "APP_NAME",
            },

          },

          {
            name: ["-b", "--bundle_id"],
            description: "Open with app bundle id",
            args: {
                  name: "BUNDLE_ID",
                  description: "BUNDLE_ID",
            },

          },

          {
            name: ["-e", "--editor"],
            description: "Open with editor command",
            args: {
                  name: "COMMAND",
                  description: "COMMAND",
            },

          },

        ],

    },

    {
      name: "plugins",
      description: "List installed plugins",
      options: [
          {
            name: ["-c", "--column"],
            description: "List in single column for completion",
            
          },

          {
            name: ["-t", "--type"],
            description: "List plugins of type",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

        ],

    },

    {
      name: "recent",
      description: "List recent entries",
      options: [
          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select from a menu of matching entries to perform additional operations",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

        ],

    },

    {
      name: "redo",
      description: "Redo an undo command",
      options: [
          {
            name: ["-f", "--file"],
            description: "Specify alternate doing file",
            args: {
                  name: "PATH",
                  description: "PATH",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select from an interactive menu",
            
          },

        ],

    },

    {
      name: "reset",
      description: "Reset the start time of an entry",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--from"],
            description: "Start and end times as a date/time range `doing done --from \"1am to 8am\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Reset items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--resume"],
            description: "Resume entry",
            
          },

          {
            name: ["-s", "--section"],
            description: "Limit search to section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--for"],
            description: "Set completion date to start date plus interval",
            args: {
                  name: "INTERVAL",
                  description: "INTERVAL",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "begin",
      description: "Reset the start time of an entry",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--from"],
            description: "Start and end times as a date/time range `doing done --from \"1am to 8am\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Reset items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--resume"],
            description: "Resume entry",
            
          },

          {
            name: ["-s", "--section"],
            description: "Limit search to section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--for"],
            description: "Set completion date to start date plus interval",
            args: {
                  name: "INTERVAL",
                  description: "INTERVAL",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "rotate",
      description: "Move entries to archive file",
      options: [
          {
            name: ["--before"],
            description: "Rotate entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-k", "--keep"],
            description: "How many items to keep in each section",
            args: {
                  name: "X",
                  description: "X",
            },

          },

          {
            name: ["--not"],
            description: "Rotate items that *don't* match search/tag filters",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section to rotate",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "sections",
      description: "List",
      
    },

    {
      name: "select",
      description: "Display an interactive menu to perform operations",
      options: [
          {
            name: ["-a", "--archive"],
            description: "Archive selected items",
            
          },

          {
            name: ["--after"],
            description: "Select entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--resume"],
            description: "Copy selection as a new entry with current time and no @done tag",
            
          },

          {
            name: ["--before"],
            description: "Select entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-c", "--cancel"],
            description: "Cancel selected items",
            
          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-d", "--delete"],
            description: "Delete selected items",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit selected item(s)",
            
          },

          {
            name: ["-f", "--finish"],
            description: "Add @done with current time to selected item(s)",
            
          },

          {
            name: ["--flag"],
            description: "Add flag to selected item(s)",
            
          },

          {
            name: ["--force"],
            description: "Perform action without confirmation",
            
          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-m", "--move"],
            description: "Move selected items to section",
            args: {
                  name: "SECTION",
                  description: "SECTION",
            },

          },

          {
            name: ["--menu"],
            description: "Use --no-menu to skip the interactive menu",
            
          },

          {
            name: ["--not"],
            description: "Select items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output entries to format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["-q", "--query"],
            description: "Initial search query for filtering",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-r", "--remove"],
            description: "Reverse -c",
            
          },

          {
            name: ["-s", "--section"],
            description: "Select from a specific section",
            args: {
                  name: "SECTION",
                  description: "SECTION",
            },

          },

          {
            name: ["--save_to"],
            description: "Save selected entries to file using --output format",
            args: {
                  name: "FILE",
                  description: "FILE",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--tag"],
            description: "Tag selected entries",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "show",
      description: "List all entries",
      options: [
          {
            name: ["-a", "--age"],
            description: "Age",
            args: {
                  name: "AGE",
                  description: "AGE",
            },

          },

          {
            name: ["--after"],
            description: "Show entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--before"],
            description: "Show entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "Max count to show",
            args: {
                  name: "MAX",
                  description: "MAX",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit matching entries with vim",
            
          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-h", "--hilite"],
            description: "Highlight search matches in output",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select from a menu of matching entries to perform additional operations",
            
          },

          {
            name: ["-m", "--menu"],
            description: "Select section or tag to display from a menu",
            
          },

          {
            name: ["--not"],
            description: "Show items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Only show entries within section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--sort"],
            description: "Sort order",
            args: {
                  name: "ORDER",
                  description: "ORDER",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "since",
      description: "List entries since a date",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["--not"],
            description: "Since items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "tag",
      description: "Add tag(s) to last entry",
      options: [
          {
            name: ["-a", "--autotag"],
            description: "Autotag entries based on autotag configuration in ~/",
            
          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "How many recent entries to tag",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-d", "--date"],
            description: "Include current date/time with tag",
            
          },

          {
            name: ["--force"],
            description: "Don't ask permission to tag all entries when count is 0",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select item(s) to tag from a menu of matching entries",
            
          },

          {
            name: ["--not"],
            description: "Tag items that *don't* match search/tag filters",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Remove given tag(s)",
            
          },

          {
            name: ["--regex"],
            description: "Interpret tag string as regular expression",
            
          },

          {
            name: ["--rename"],
            description: "Replace existing tag with tag argument",
            args: {
                  name: "ORIG_TAG",
                  description: "ORIG_TAG",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["-u", "--unfinished"],
            description: "Tag last entry",
            
          },

          {
            name: ["-v", "--value"],
            description: "Include a value",
            args: {
                  name: "VALUE",
                  description: "VALUE",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "tag_dir",
      description: "Set the default tags for the current directory",
      options: [
          {
            name: ["--clear"],
            description: "Remove all default_tags from the local",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Use default editor to edit tag list",
            
          },

          {
            name: ["-r", "--remove"],
            description: "Delete tag(s) from the current list",
            
          },

        ],

    },

    {
      name: "tags",
      description: "List all tags in the current Doing file",
      options: [
          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--counts"],
            description: "Show count of occurrences",
            
          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select items to scan from a menu of matching entries",
            
          },

          {
            name: ["-l", "--line"],
            description: "Output in a single line with @ symbols",
            
          },

          {
            name: ["--not"],
            description: "Show items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--order"],
            description: "Sort order",
            args: {
                  name: "ORDER",
                  description: "ORDER",
            },

          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--sort"],
            description: "Sort by name or count",
            args: {
                  name: "SORT_ORDER",
                  description: "SORT_ORDER",
            },

          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "template",
      description: "Output HTML",
      options: [
          {
            name: ["-c", "--column"],
            description: "List in single column for completion",
            
          },

          {
            name: ["-l", "--list"],
            description: "List all available templates",
            
          },

          {
            name: ["-p", "--path"],
            description: "Save template to alternate location",
            args: {
                  name: "DIRECTORY",
                  description: "DIRECTORY",
            },

          },

          {
            name: ["-s", "--save"],
            description: "Save template to file instead of STDOUT",
            
          },

        ],

    },

    {
      name: "test",
      description: "Test Stuff",
      
    },

    {
      name: "today",
      description: "List entries from today",
      options: [
          {
            name: ["--after"],
            description: "View entries after specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--before"],
            description: "View entries before specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["--from"],
            description: "Time range to show `doing today --from \"12pm to 4pm\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Specify a section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

        ],

    },

    {
      name: "todo",
      description: "Add an item as a Todo",
      options: [
          {
            name: ["--ask"],
            description: "Prompt for note via multi-line input",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Edit entry with vim",
            
          },

          {
            name: ["-n", "--note"],
            description: "Note",
            args: {
                  name: "TEXT",
                  description: "TEXT",
            },

          },

        ],

    },

    {
      name: "undo",
      description: "Undo the last X changes to the Doing file",
      options: [
          {
            name: ["-f", "--file"],
            description: "Specify alternate doing file",
            args: {
                  name: "PATH",
                  description: "PATH",
            },

          },

          {
            name: ["-i", "--interactive"],
            description: "Select from recent backups",
            
          },

          {
            name: ["-p", "--prune"],
            description: "Remove old backups",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["-r", "--redo"],
            description: "Redo last undo",
            
          },

        ],

    },

    {
      name: "update",
      description: "Update doing to the latest version",
      options: [
          {
            name: ["--beta"],
            description: "Check for pre-release version",
            
          },

        ],

    },

    {
      name: "view",
      description: "Display a user-created view",
      options: [
          {
            name: ["--after"],
            description: "Show entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--age"],
            description: "Age",
            args: {
                  name: "AGE",
                  description: "AGE",
            },

          },

          {
            name: ["--before"],
            description: "Show entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["--bool"],
            description: "Boolean used to combine multiple tags",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["-c", "--count"],
            description: "Count to display",
            args: {
                  name: "COUNT",
                  description: "COUNT",
            },

          },

          {
            name: ["--case"],
            description: "Case sensitivity for search string matching [(c)ase-sensitive",
            args: {
                  name: "TYPE",
                  description: "TYPE",
            },

          },

          {
            name: ["--color"],
            description: "Include colors in output",
            
          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["--from"],
            description: "Date range",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["-h", "--hilite"],
            description: "Highlight search matches in output",
            
          },

          {
            name: ["-i", "--interactive"],
            description: "Select from a menu of matching entries to perform additional operations",
            
          },

          {
            name: ["--not"],
            description: "Show items that *don't* match search/tag filters",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--search"],
            description: "Filter entries using a search query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag"],
            description: "Filter entries by tag",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--totals"],
            description: "Show intervals with totals at the end of output",
            
          },

          {
            name: ["--val"],
            description: "Perform a tag value query",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["-x", "--exact"],
            description: "Force exact search string matching",
            
          },

        ],

    },

    {
      name: "views",
      description: "List available custom views",
      options: [
          {
            name: ["-c", "--column"],
            description: "List in single column",
            
          },

          {
            name: ["-e", "--editor"],
            description: "Open YAML for view in editor",
            
          },

          {
            name: ["-o", "--output"],
            description: "Output/edit view in alternative format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["-r", "--remove"],
            description: "Delete view config",
            
          },

        ],

    },

    {
      name: "wiki",
      description: "Output a tag wiki",
      options: [
          {
            name: ["--after"],
            description: "Include entries newer than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-b", "--bool"],
            description: "Tag boolean",
            args: {
                  name: "BOOLEAN",
                  description: "BOOLEAN",
            },

          },

          {
            name: ["--before"],
            description: "Include entries older than date",
            args: {
                  name: "DATE_STRING",
                  description: "DATE_STRING",
            },

          },

          {
            name: ["-f", "--from"],
            description: "Date range to include",
            args: {
                  name: "DATE_OR_RANGE",
                  description: "DATE_OR_RANGE",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Section to rotate",
            args: {
                  name: "SECTION_NAME",
                  description: "SECTION_NAME",
            },

          },

          {
            name: ["--search"],
            description: "Search filter",
            args: {
                  name: "QUERY",
                  description: "QUERY",
            },

          },

          {
            name: ["--tag"],
            description: "Tag filter",
            args: {
                  name: "TAG",
                  description: "TAG",
            },

          },

        ],

    },

    {
      name: "yesterday",
      description: "List entries from yesterday",
      options: [
          {
            name: ["--after"],
            description: "View entries after specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--before"],
            description: "View entries before specified time",
            args: {
                  name: "TIME_STRING",
                  description: "TIME_STRING",
            },

          },

          {
            name: ["--config_template"],
            description: "Output using a template from configuration",
            args: {
                  name: "TEMPLATE_KEY",
                  description: "TEMPLATE_KEY",
            },

          },

          {
            name: ["--duration"],
            description: "Show elapsed time on entries without @done tag",
            
          },

          {
            name: ["--from"],
            description: "Time range to show `doing yesterday --from \"12pm to 4pm\"`",
            args: {
                  name: "TIME_RANGE",
                  description: "TIME_RANGE",
            },

          },

          {
            name: ["-o", "--output"],
            description: "Output to export format",
            args: {
                  name: "FORMAT",
                  description: "FORMAT",
            },

          },

          {
            name: ["--only_timed"],
            description: "Only show items with recorded time intervals",
            
          },

          {
            name: ["-s", "--section"],
            description: "Specify a section",
            args: {
                  name: "NAME",
                  description: "NAME",
            },

          },

          {
            name: ["--save"],
            description: "Save all current command line options as a new view",
            args: {
                  name: "VIEW_NAME",
                  description: "VIEW_NAME",
            },

          },

          {
            name: ["-t", "--times"],
            description: "Show time intervals on @done tasks",
            
          },

          {
            name: ["--tag_order"],
            description: "Tag sort direction",
            args: {
                  name: "DIRECTION",
                  description: "DIRECTION",
            },

          },

          {
            name: ["--tag_sort"],
            description: "Sort tags by",
            args: {
                  name: "KEY",
                  description: "KEY",
            },

          },

          {
            name: ["--template"],
            description: "Override output format with a template string containing %placeholders",
            args: {
                  name: "TEMPLATE_STRING",
                  description: "TEMPLATE_STRING",
            },

          },

          {
            name: ["--title"],
            description: "Title string to be used for output formats that require it",
            args: {
                  name: "TITLE",
                  description: "TITLE",
            },

          },

          {
            name: ["--totals"],
            description: "Show time totals at the end of output",
            
          },

        ],

    },

  ],
};
export default completionSpec;
