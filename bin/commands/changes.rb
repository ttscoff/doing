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

CHANGE_RX = /^(?:(?:(?:[<>=]|p(?:rior)|b(?:efore)|o(?:lder)|s(?:ince)|a(?:fter)|n(?:ewer))? *[\d.*?]+ *)+|(?:[\d.]+ *-+ *[\d.]+))$/

desc 'List recent changes in Doing'
long_desc %(Display a formatted list of changes in recent versions.

            Without flags, displays only the most recent version.
            Use --lookup or --all for history.)
command %i[changes changelog] do |c|
  c.desc 'Display all versions'
  c.switch %i[a all], default_value: false, negatable: false

  c.desc %(Look up a specific version. Specify versions as "MAJ.MIN.PATCH", MIN
           and PATCH are optional. Use > or < to see all changes since or prior
           to a version.)
  c.arg_name 'VERSION'
  c.flag %i[l lookup], must_match: CHANGE_RX

  c.desc %(Show changelogs matching search terms (uses pattern-based searching).
           Add slashes to search with regular expressions, e.g. `--search "/output.*flag/"`)
  c.flag %i[s search]

  c.desc 'Sort order (asc/desc)'
  c.arg_name 'ORDER'
  c.flag %i[sort], must_match: REGEX_SORT_ORDER, default_value: :desc, type: OrderSymbol

  c.desc 'Only output changes, no version numbers, headers, or dates'
  c.switch %i[C changes], default_value: false, negatable: false

  c.desc 'Output raw Markdown'
  c.switch %i[m md markdown], default_value: false, negatable: false

  c.example 'doing changes', desc: 'View changes in the current version'
  c.example 'doing changes --all', desc: 'See the entire changelog'
  c.example 'doing changes --lookup 2.0.21', desc: 'See changes from version 2.0.21'
  c.example 'doing changes --lookup "> 2.1"', desc: 'See all changes since 2.1.0'
  c.example 'doing changes --search "tags +bool"', desc: 'See all changes containing "tags" and "bool"'
  c.example 'doing changes -l "> 2.1" -s "pattern"', desc: 'Lookup and search can be combined'

  c.action do |_global_options, options, _args|
    cl = Doing::Changes.new(lookup: options[:lookup], search: options[:search], changes: options[:changes], sort: options[:sort])

    content = if options[:all] || options[:search] || options[:lookup]
                cl.to_s
              else
                cl.latest
              end

    parsed = if options[:markdown] || !$stdout.isatty
               content
             else
               TTY::Markdown.parse(content, width: 80, theme: MARKDOWN_THEME, symbols: { override: { bullet: '•' } })
             end

    Doing::Pager.paginate = true
    Doing::Pager.page parsed
  end
end
