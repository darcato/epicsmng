#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as superuser"
    exit 1
fi

#using "local" folder as this will not be managed by a packet manager
dest="/usr/local/bin/"

#create source folder if not present
echo "Installing epicsmng..."
if ! install -m 755 ./epicsmng $dest; then
    echo "Installation failed"
    exit 1
fi

install -m 644 ./epicsmng-completion.bash /etc/bash_completion.d/
rm -rf $HOME/.config/epicsmng/src/
rm -rf $HOME/.local/share/epicsmng/

userHome=$(eval echo ~$(logname))
rm -rf $userHome/.config/epicsmng/src/
rm -rf $userHome/.local/share/epicsmng/

echo "Done!"
