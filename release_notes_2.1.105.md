### 2.1.105

2026-03-23 08:30

#### NEW

- Add `--totals_format` to totals-capable output so users can choose how `Total tracked` is displayed, including `hmclock`, `natural`, and other time formats.
- Add `averages` totals format to show `Total tracked` with cumulative hours/minutes and average hours per day across the filtered date span.

#### IMPROVED

- Keep existing totals output as the default (`clock`) unless overridden by CLI option or config.
- Allow configuring a default totals display format with the new `totals_format` setting.

