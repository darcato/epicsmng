#!/usr/bin/env bash

#Uninstalling from local folder on HOME
dest="$HOME/.local/bin"
share="$HOME"/.local/share/epicsmng/
completion_dir="$HOME/.bash_completion.d/"

#Remove executable
echo "Removing epicsmng..."
if ! rm -f "$dest"/epicsmng; then
    echo "Failed"
    exit 1
fi

#Remove bash completion
rm -f "$completion_dir/epicsmng-completion.bash"

#Remove share folder (with src)
rm -rf "$share"

echo "Done!"
