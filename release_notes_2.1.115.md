### 2.1.115

2026-04-29 04:23

#### NEW

- Template placeholders can use `*` as a stretch width marker so titles and notes expand to fit available terminal columns.
- Template version 2 can resolve placeholder width settings from config, including `stretch` and `auto` widths.

#### IMPROVED

- Stretch title widths now account for trailing fixed-width placeholders, color tokens, and live terminal width so right-side content stays aligned.

#### FIXED

- Note placeholders no longer reduce `%*title` width, and `%*note` wraps to the full note block width minus configured padding.

