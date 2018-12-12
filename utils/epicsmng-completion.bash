#!/usr/bin/env bash

# the commands available as first argument of epicsmng
commands="makemodules cleanmodules listmodules configureioc version"

#custom function to autocomplete epicsmng
function _epicsmng_autocomplete_()
{
    #if typing the first argument -> autocomplete with one of the commands
    #in all the other cases, fallback to default
    case $COMP_CWORD in
        1) mapfile -t COMPREPLY < <(compgen -W "$commands" -- "${COMP_WORDS[COMP_CWORD]}")
           return 0;;
        *) return 1;;
    esac
}

# tell bash to use the function to autocomplete epicsmng
# if the function fails (return 1), fallback to default completion
complete -o default -F _epicsmng_autocomplete_ epicsmng