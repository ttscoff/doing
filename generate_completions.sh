#!/bin/bash

scripts/generate_fish_completions.rb > lib/completion/doing.fish
scripts/generate_bash_completions.rb > lib/completion/doing.bash
scripts/generate_zsh_completions.rb > lib/completion/_doing.zsh
