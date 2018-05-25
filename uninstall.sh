#/usr/bin/env bash

if [ "`id -u`" -ne 0 ]; then
    echo "Please run as superuser"
    exit 1
fi

#using "local" folder as this will not be managed by a packet manager
dest="/usr/local/bin/"

#create source folder if not present
echo "Removing epicsmng..."
if ! rm -f $dest/epicsmng; then
    echo "Failed"
    exit 1
fi

rm -f /etc/bash_completion.d/epicsmng-completion.bash
rm -rf /home/$(logname)/.config/epicsmng/src/

echo "Done!"
