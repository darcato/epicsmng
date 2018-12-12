#!/usr/bin/env bash
# Installed by epicsmng

for bcfile in ./.bash_completion.d/* ; do
    [ -f "$bcfile" ] && source "$bcfile"
done