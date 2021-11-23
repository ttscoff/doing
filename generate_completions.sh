#!/bin/bash

bundle exec bin/doing completion --type fish --file lib/completion/doing.fish
bundle exec bin/doing completion --type bash --file lib/completion/doing.bash
bundle exec bin/doing completion --type zsh --file lib/completion/_doing.zsh
