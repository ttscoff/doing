### 2.1.120

2026-04-29 14:55

#### IMPROVED

- `COLUMNS` now overrides live terminal width detection for template stretch calculations.

#### FIXED

- `%*note` now pads every wrapped note line to the available block width instead of only padding the first note line.
- Inline `%*` widths are preserved under `template_version: 2` unless the placeholder is managed by the template `elements` config.
- Stretch title widths now reserve implicit `%shortdate` padding, visible placeholder prefixes, and same-line note spacing so right-side fields do not wrap by one column.

