#create source folder if not present
if [ ! -d $src ]; then
    echo "Installing source folder"
    if ! sudo install -d -o $(whoami) -g $(id -n -g $(whoami)) -m 775 $src; then
        echo "Cannot create source folder $src"
        exit 1
    fi
fi