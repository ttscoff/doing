# @@changelog @@changes

MARKDOWN_THEME = {
  em: %i[white dark],
  header: %i[cyan bold],
  hr: :yellow,
  link: %i[bright_cyan underline],
  list: :yellow,
  strong: %i[yellow bold],
  table: :yellow,
  quote: :yellow,
  image: :bright_black,
  note: :yellow,
  comment: :bright_black
}.deep_freeze

module Doing
  # changes command methods
  class ChangesCommand
    CHANGE_RX = /^(?:(?:(?:[<>=]+|p(?:rior)|b(?:efore)|o(?:lder)|s(?:ince)|a(?:fter)|n(?:ewer))? *[0-9.*?]{1,10} *)+|(?:[\d.]+ *(?:-|to)+ *[0-9.]{1,10}))$/

    def add_options(cmd)
      cmd.desc 'Display all versions'
      cmd.switch %i[a all], default_value: false, negatable: false

      cmd.desc %(Look up a specific version. Specify versions as "MAJ.MIN.PATCH", MIN
               and PATCH are optional. Use > or < to see all changes since or prior
               to a version. Wildcards (*?) accepted unless using < or >.)
      cmd.arg_name 'VERSION'
      cmd.flag %i[l lookup], must_match: CHANGE_RX

      cmd.desc %(Show changelogs matching search terms (uses pattern-based searching).
               Add slashes to search with regular expressions, e.g. `--search "/output.*flag/"`)
      cmd.flag %i[s search]

      cmd.desc 'Sort order (asc/desc)'
      cmd.arg_name 'ORDER'
      cmd.flag %i[sort], must_match: REGEX_SORT_ORDER, default_value: :desc, type: OrderSymbol

      cmd.desc 'Only output changes, no version numbers, headers, or dates'
      cmd.switch %i[C changes], default_value: false, negatable: false

      cmd.desc 'Include (CHANGE|NEW|IMPROVED|FIXED) prefix on each line'
      cmd.switch %i[p prefix]

      cmd.desc 'Output raw Markdown'
      cmd.switch %i[m md markdown], default_value: false, negatable: false

      cmd.desc 'Force rendered output'
      cmd.switch %i[render], default_value: false, negatable: false

      cmd.desc 'Open changelog in interactive viewer'
      cmd.switch %i[i interactive], default_value: false, negatable: false
    end

    def add_examples(cmd)
      cmd.example 'doing changes', desc: 'View changes in the current version'
      cmd.example 'doing changes --all', desc: 'See the entire changelog'
      cmd.example 'doing changes --lookup 2.0.21', desc: 'See changes from version 2.0.21'
      cmd.example 'doing changes --lookup "> 2.1"', desc: 'See all changes since 2.1.0'
      cmd.example 'doing changes --search "tags +bool"', desc: 'See all changes containing "tags" and "bool"'
      cmd.example 'doing changes -l "> 2.1" -s "pattern"', desc: 'Lookup and search can be combined'
    end
  end
end

desc 'List recent changes in Doing'
long_desc %(Display a formatted list of changes in recent versions.

            Without flags, displays only the most recent version.
            Use --lookup or --all for history.)
command %i[changes changelog] do |c|
  cmd = Doing::ChangesCommand.new
  cmd.add_options(c)
  cmd.add_examples(c)

  c.action do |_global_options, options, _args|
    cl = Doing::Changes.new(lookup: options[:lookup],
                            search: options[:search],
                            changes: options[:changes],
                            prefix: options[:prefix],
                            sort: options[:sort])

    if options[:interactive]
      cl.interactive
    else
      content = if options[:all] || options[:search] || options[:lookup]
                  cl.to_s
                else
                  cl.latest
                end

      parsed = if (options[:markdown] || !$stdout.isatty) && !options[:render]
                 content
               else
                 TTY::Markdown.parse(content, width: 80, theme: MARKDOWN_THEME, symbols: { override: { bullet: '•' } })
               end

      Doing::Pager.paginate = true
      Doing::Pager.page parsed
    end
  end
end
