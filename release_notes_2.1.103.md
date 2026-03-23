### 2.1.103

2026-03-23 04:24

#### NEW

- Add `--by` totals grouping (`tags` or `section`) to totals-capable commands so users can switch between tag totals and section totals, including repeated ordering like `--by section --by tags`.

#### IMPROVED

- The CLI now falls back to `reline` when `readline` is unavailable (for example on Ruby 4 builds) so commands and tests still run.
- Carry totals grouping through exports so HTML, Markdown, JSON, Day One, template, and wiki outputs reflect the selected grouping.
- Accept dashed long-option aliases for underscore flags (for example `--only-timed`, `--tag-sort`, and `--tag-order`) while preserving existing underscore forms.
- Accept dashed subcommand aliases for underscore commands so `doing tag-dir` works the same as `doing tag_dir`.
- Reduce tag test runtime by removing unnecessary debug-mode CLI invocations in search/tag assertions.
- `--by` totals grouping now accepts `project` and `p` as aliases for section totals, so `--by section`, `--by project`, and `--by p` behave the same.

#### FIXED

- Tag totals table (timer_format: human) now expands to fit budget text and pads shorter lines so borders align correctly instead of breaking layout
- `doing done --from` now correctly handles `12pm to 1pm` and `noon to 1:00pm` without parse errors.
- Time range values from `--from` are now normalized before date formatting so `done` and `reset` no longer fail with string/time type errors.
- Non-interactive runs now return default prompt answers without reopening `/dev/tty`, preventing CLI failures in automated test contexts.
- Keep argument mangling scoped to options/command dispatch so positional string arguments are not rewritten, including tokens after `--`.
- Correct human totals box rendering so the top border width matches the body/footer width and no longer appears one character too wide.
- Totals grouping normalization now maps project aliases consistently to section output across command parsing and rendering paths.

