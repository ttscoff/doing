#!/bin/bash
export GLI_DEBUG=true
export EDITOR="/usr/bin/vim"
alias bdoing="GLI_DEBUG=true bundle exec bin/doing"

shopt -s nocaseglob
shopt -s histappend
shopt -s histreedit
shopt -s histverify
shopt -s cmdhist

cd /doing
bundle install
