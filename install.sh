#!/usr/bin/env bash

release="v2.1.0-release"

#Installing on local folder on HOME
dest="$HOME/.local/bin"
share="$HOME/.local/share/epicsmng"
configdir="$HOME/.config/epicsmng"
completion_dir="$HOME/.bash_completion.d"
settingsdir="$configdir/settings"
patchesdir="$configdir/patches"

# cd to repository folder
cd "$(dirname "$0")" || exit 1

utils="./utils/"

#Install the executable
echo "Installing epicsmng..."
install -d "$dest"
version=$(git describe --tags 2>/dev/null || echo "$release")
if ! sed -e "s/_VERSION_/${version}/" ./epicsmng > epicsmng_tmp; then
    echo "Installation failed"
    exit 1
fi

if ! install -m 755 ./epicsmng_tmp "$dest/epicsmng"; then
    echo "Installation failed"
    exit 1
fi
rm epicsmng_tmp

#Update PATH if necessary
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "export PATH=\$PATH:$dest # Added by epicsmng" >> "$HOME"/.bashrc
    echo "PATH updated: open a new shell to start using epicsmng"
fi

#Install the bash completion
install -d "$completion_dir"
if ! grep -qs "Installed by epicsmng" "$HOME/.bash_completion"; then
    [ -f "$HOME/.bash_completion" ] && mv "$HOME/.bash_completion"  "$completion_dir/original.bash"
    cp "$utils/completion_include.bash" "$HOME/.bash_completion"
fi
install -m 644 "$utils/epicsmng-completion.bash" "$completion_dir"

#Remove existing sources to avoid conflicts
rm -rf "$share"

#Install default directories
if ! install -d "$settingsdir"; then
    echo "WARNING: cannot create user configuration directory $settingsdir"
fi

if ! install -d "$patchesdir"; then
    echo "WARNING: cannot create patches directory $patchesdir"
fi

#Install default config overwriting existing one
cp "$utils/default.settings" "$configdir"

#if configdir empty, populate it with example user config
if [ -z "$(ls -A "$settingsdir")" ]; then
    cp "$utils/user.settings" "$settingsdir"
fi

echo "Done!"
