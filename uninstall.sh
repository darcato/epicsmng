#!/usr/bin/env bash

#Path locations
dest="/usr/local/bin"
share="/usr/local/share/epicsmng"
src="$share/src"
configdir="/etc/epicsmng"
completion_dir="/etc/bash_completion.d"
settingsdir="$configdir/settings"
patchesdir="$configdir/patches"

if [[ $UID != 0 ]]; then
    #Path locations
    dest="$HOME/.local/bin"
    share="$HOME/.local/share/epicsmng"
    configdir="$HOME/.config/epicsmng"
    completion_dir="$HOME/.bash_completion.d"
    settingsdir="$configdir/settings"
    patchesdir="$configdir/patches"
fi

#Remove executable
echo "Removing epicsmng..."
if ! rm -f "$dest/epicsmng"; then
    echo "Failed"
    exit 1
fi

#Remove bash completion
rm -f "$completion_dir/epicsmng-completion.bash"

#Remove share folder (with src)
rm -rf "$share"

echo "Done!"
