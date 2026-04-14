### 2.1.107

2026-04-14 17:46

#### CHANGED

- Version bump to 2.1.106 (Gemfile.lock and lib/doing/version.rb).

#### FIXED

- Plugin directories configured with tilde paths (for example under plugins.plugin_path) now expand to the real filesystem path before checking existence, creating the directory, and loading plugins, so a literal tilde folder is not created by mistake.

