#!/bin/bash

base_url="https://git.launchpad.net/epics-base"
asyn_url='https://github.com/epics-modules/asyn.git'
motort_url='https://github.com/epics-modules/motor'
ipac_url="https://github.com/epics-modules/ipac.git"
streamdevice_url="https://github.com/paulscherrerinstitute/StreamDevice.git"
calc_url='https://github.com/epics-modules/calc.git'
modbus_url="https://github.com/epics-modules/modbus.git"
autosave_url="https://github.com/epics-modules/autosave.git"
busy_url="https://github.com/epics-modules/busy.git"

gensub_url="http://www.observatorysciences.co.uk/downloads/$fname"

cyusbdevsup_url="git@baltig.infn.it:epicscs/cyusbdevsup.git"
beckmotor_url="git@baltig.infn.it:epicscs/BeckMotor_EPICS.git"

asyn_requires="base"
asyn_optionals="sncseq ipac"

cyusbdevsup_requires="base asyn"
cyusbdevsup_optionals=""

motor_requires="base asyn"
motor_optionals="busy ipac sncseq"

ipac_requires="base"
ipac_optionals=""

calc_requires="base"
calc_optionals="sscan sncseq"

beckmotor_requires="base asyn motor"
beckmotor_optionals=""

modbus_requires="base asyn"
modbus_optionals=""

autosave_requires="base"
autosave_optionals=""

busy_requires="base autosave asyn"
busy_optionals=""

#execute here a configuration file which can ovverride default macro values

#this creates the folder containing the source of a module
#clones the repository
#and checkout to the required version
function prepare_git_src {
    remote="$1" #coincide with folder name
    module="$2"
    version="$3"
    
    cd $src
    #create folder with same name as module if not already present
    if [ ! -d "$module" ]; then
        echo "Cloning from repo $remote"
        if ! git clone "$remote" "$module"; then
            return 1
        fi
        cd "$module"
    else  #if already present, simply fetch updates
        cd "$module"
        echo "Updating from repo $remote"
        if ! git fetch --all; then
            echo "Git fetch failed"
            #do not return error, may still find required version on local repo
        fi
    fi    
    #discard local changes
    git checkout -- . 
    #checkout to the desired version
    if ! git checkout "$version"; then
        echo "ERRORE: Git version tag $version not found."
        return 1
    fi
    cd $top    
    return 0
}

function set_config {
    #file, token, value
    if grep -e "[# \t]*$2[ \t]*=" $1 ; then
        sed -i -e "s/[# \t]*$2[ \t]*=.*/$2=$(echo $3 | sed -e 's/\//\\\//g')/" $1
    else
        echo "$2=$3" >> $1
    fi    
}

function disable_config {
    #file, token
    sed -i -e "s/\([ \t]*$2[ \t]*=.*\)/# \1/" $1
}


function set_release_par {
    #token, value
    set_config configure/RELEASE $1 $2
}

function disable_release_par {
    #token
    disable_config configure/RELEASE $1
}

#sets configure/release with path of the required modules to compile a module
#it reads the required ones from $module_requires variable
function set_requires {
    mod_to_build=$1

    requires="_requires"
    requires=$mod_to_build$requires  #something like asyn_requires
    for m in ${!requires}; do   #expanded to $asyn_requires
        echo "$mod_to_build requires $m"
        module_up="$(echo -e "$m" | tr '[:lower:]' '[:upper:]')" #to uppercase
        if [ "$module_up" == 'BASE' ]; then
            module_up='EPICS_BASE'
        fi
        
        #search for the required module inside the modules to be installed  --TODO: change to installed ones
        indx=-1
        for i in ${!modules[@]}; do
            if [ ${modules[$i]} = $m ]; then
                indx=$i
                break
            fi
        done

        #if not found: error, it is required
        if [ "$indx" = -1 ]; then 
            echo "ERROR: $mod_to_build requires $m"
            return 1
        fi

        #set path inside module release
        set_release_par "$module_up" "$target/$m-${versions[$indx]}"
    done
}

#sets configure/release with path of the optional modules to compile a module
#it reads the optional ones from $module_optionals variable
function set_optionals {
    mod_to_build=$1

    optionals="_optionals"
    optionals=$mod_to_build$optionals  #something like asyn_optionals
    for m in ${!optionals}; do   #expanded to $asyn_optionals
        echo "$mod_to_build can link to $m"
        module_up="$(echo -e "$m" | tr '[:lower:]' '[:upper:]')" #to uppercase
        if [ "$module_up" == 'BASE' ]; then
            module_up='EPICS_BASE'
        fi

        #search for the required module inside the modules to be installed  --TODO: change to installed ones
        indx=-1
        for i in ${!modules[@]}; do
            if [ ${modules[$i]} = $m ]; then
                indx=$i
                break
            fi
        done

        #if not found, comment it in configure/RELEASE, else uncomment and set path
        if [ "$indx" = -1 ]; then 
            echo "Commenting $module_up"
            disable_release_par "$module_up"
        else
            echo "Setting $module_up"
            set_release_par "$module_up" "$target/$m-${versions[$indx]}"
        fi
    done
}

function _compile_git {
    module="$1"
    version="$2"
    dest="$target/$module-$version"
    
    url="_url"
    url="$module$url"
    if ! prepare_git_src ${!url} "$module" "$version"; then
        return 1
    fi
    
    cd $src/$module
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    
    set_requires "$module"
    set_optionals "$module"

    #make distclean
    make
}


function compile_base {
    dest="$target/base-$1"
    if ! prepare_git_src $base_url 'base' $1; then
        return 1
    fi
    
    cd $src/base
    export EPICS_HOST_ARCH=$(./startup/EpicsHostArch)
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    #make distclean
    make
    cp -r startup $dest/
    cp -r config $dest/
};


function compile_asyn {
    version=$1 
    _compile_git "asyn" "$version"
}; 

function compile_gensub {
    echo "Compiling gensub $1 as support for base $2."
    #base="$(pwd)/bases/$2"
    #support="$base/support"
    dest="$support/gensub/$1"

    fname="genSubV$1.tar.gz"
    mkdir -p $src/gensub
    cd $src/gensub
    if [ -d $1 ]; then
        echo "folder exists"
        cd $1
    elif [ -f $fname ]; then
        echo "file exists"
        mkdir $1
        tar zxvf $fname --strip-components=1 -C $1
        cd $1 
    else
        url="http://www.observatorysciences.co.uk/downloads/$fname"
        echo "downloading"
        wget $url
        mkdir $1
        tar zxvf $fname --strip-components=1 -C $1
        cd $1 
    fi
    #EPICS_HOST_ARCH=$(src/epics-base/startup/EpicsHostArch)
    #sed -i -e "s/^#INSTALL_LOCATION_APP.*/INSTALL_LOCATION_APP=$(echo $dest | sed -e 's/\//\\\//g')/" configure/RELEASE    
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    #sed -i -e "s/EPICS_BASE=.*/EPICS_BASE=$(echo $base | sed -e 's/\//\\\//g')/" configure/RELEASE    
    set_release_par 'EPICS_BASE' $base
    #sed -i -e "s/^\(CROSS_COMP.*\)/#\1/" configure/CONFIG    
    disable_config configure/CONFIG 'CROSS_COMP'
    make distclean
    make
    #rm -rf $1
};

function compile_cyusbdevsup { 
    version=$1 
    _compile_git "asyn" "$version"
};


function compile_motor {
    version=$1
    _compile_git "motor" "$version"
};


function compile_ipac {
    version=$1
    _compile_git "ipac" "$version"
}

function compile_streamdevice {
    base="$(pwd)/bases/$2"
    support="$base/support"
    dest="$support/ipac/$1"
    arch=$($base/startup/EpicsHostArch)
    asyn="\$(SUPPORT)/$3"
    cd src
    if [ ! -d StreamDevice ]; then
        mkdir StreamDevice;
        cd StreamDevice
        $base/bin/$arch/makeBaseApp.pl -t support empty
        git clone https://github.com/paulscherrerinstitute/StreamDevice.git
    fi
    cd StreamDevice
    sed -i -e "s/EPICS_BASE=.*/EPICS_BASE=$(echo $base | sed -e 's/\//\\\//g')/" configure/RELEASE    
    sed -i -e "s/^ASYN=.*/ASYN=$(echo $asyn | sed -e 's/\//\\\//g')/" configure/RELEASE    
    cd StreamDevice
    

}

function compile_calc {
    version=$1
    _compile_git "calc" "$version"
}

function compile_beckmotor {
    version=$1
    _compile_git "beckmotor" "$version"
    dest="$support/beckmotor/$1"
}

function compile_modbus {
    version=$1
    _compile_git "modbus" "$version"
}

function compile_autosave {
    version=$1
    _compile_git "autosave" "$version"
}

function compile_busy {
    version=$1
    _compile_git "busy" "$version"
}





# USAGE:
# ./compile.sh [-C <path>] configuration
#      configuration - a config file describing the epics modules to be installed



src="/usr/src/epics/"
top="$(pwd)"  #top default path is "."

usage() { 
    echo "USAGE: $0 [-C <path>] configuration"
    echo "     configuration - a config file describing the epics modules to be installed"
    exit 1; 
}

# parse optional argument [-C <top>]
while getopts ":C:" o; do
    case "${o}" in
        C)
            top="$(realpath ${OPTARG})"  #save absolute path in top
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# if the supplied path is an empty string, error
if [ -z "$top" ]; then
    usage
fi

# the first non-optional parameter must be the config file
if [ "$#" -ne 1 ]; then
    echo "Wrong number of parameters"
    usage
fi

configfile="$1"

# if I cannot read it (file not present or unreadable) error
if [ ! -w "$configfile" ]; then
    echo "Cannot read file $configfile"
    exit 1
fi

#echo configuration name
confname="$(basename -- "$configfile")"
confname="${confname%.*}"
echo " Configuration $confname"

#parse config file
tmpfile=$(mktemp)  #create temporary file
grep -o '^[^#]*' "$configfile" > "$tmpfile"  #a copy without comments
declare -a modules #an array to store found modules
declare -a versions #an array to store found versions
while IFS='=' read module version
do
    if [[ $version ]]
    then
        module="$(echo -e "$module" | tr '[:upper:]' '[:lower:]')" #to lowercase
        module="$(echo -e "$module" | tr -d '[:space:]')" #remove spaces
        modules+=( "$module" ) #add to array
        version="$(echo -e "$version" | tr -d '[:space:]')" #to lowercase
        versions+=( "$version" ) #add to array
        echo "  $module - $version"
    fi
done < "$tmpfile"
rm "$tmpfile"


echo ${modules[0]}
if [ ${modules[0]} != "base" ] && [ ${modules[0]} != "Base" ] && [ ${modules[0]} != "BASE" ]; then
    echo "ERROR: base must be the first module in the configuration"
    exit 0
fi

#where to install binaries
modulespath="$top/modules"
target="$modulespath/$confname"

#create source folder if not present
if [ ! -d $src ]; then
    echo "Installing source folder"
    if ! sudo install -d -o $(whoami) -g $(id -n -g $(whoami)) -m 775 $src; then
        echo "Cannot create source folder $src"
        exit 1
    fi
fi

#create modules folder if not present
if [ ! -d $modulespath ]; then
    if ! mkdir $modulespath; then
        echo "Cannot create modules folder $modulespath"
        exit 1
    fi
fi

#create configuration folder if not present
if [ ! -d $target ]; then
    if ! mkdir $target; then
        echo "Cannot create configuration folder $target"
        exit 1
    fi
fi

#iterate on arrays and compile corresponding module
for i in "${!modules[@]}"; do     
    echo "---"
    echo "Compiling ${modules[$i]}:${versions[$i]}"
    if ! compile_"${modules[i]}" ${versions[$i]}; then     #portare in minuscolo il comando
        echo "ERROR while compiling ${modules[$i]}-${versions[$i]}"
        exit 1
    fi
done

echo "--- Completed ---"

exit 0

