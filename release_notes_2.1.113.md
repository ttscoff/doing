### 2.1.113

2026-04-25 04:58

#### FIXED

- `--no-color` output no longer leaves ANSI reset codes around highlighted tags when `tags_color` is configured, so commands like `doing --no-color last` can be piped or copied cleanly.

