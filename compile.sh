#!/bin/bash


function prepare_git_src {
    cd src
    if [ ! -d $2 ]; then
        echo "Cloning from repo"
        if ! git clone $1 $2; then
            return 1
        fi
        cd $2
    else
        cd $2
        echo "Updating from repo"
        if ! git fetch --all; then
            return 1
        fi
    fi    
    git co -- . 
    if ! git co $3; then
        echo "ERRORE: Git version tag $3 not found."
        return 1
    fi
    #echo "checkout $3"
    cd ../..    
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

function set_dep {
    #module, release
    set_release_par $1 $support/$(echo $1 | tr '[:upper:]' '[:lower:]')/$2
}



function compile_base {
    url="https://git.launchpad.net/epics-base"
    dest="$(pwd)/bases/$1"
    if ! prepare_git_src $url 'base' $1; then
        return 1
    fi
    cd src/base
    EPICS_HOST_ARCH=$(./startup/EpicsHostArch)
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    make distclean
    make
    cp -r startup $dest/
    cp -r config $dest/    
};


function compile_asyn {
    url='https://github.com/epics-modules/asyn.git'
    dest="$support/asyn/$1"
    export EPICS_HOST_ARCH=$arch

    if ! prepare_git_src $url 'asyn' $1; then
        return 1
    fi
    cd src/asyn
    # per qualche ragione assurda non funziona INSTALL_LOCATION_APP
    set_config configure/CONFIG 'INSTALL_LOCATION' $dest
    set_release_par 'INSTALL_LOCATION_APP' $dest
    set_release_par 'EPICS_BASE' $base
    set_release_par 'SUPPORT' $support
    disable_release_par 'IPAC'
    disable_release_par 'SNCSEQ'
    make distclean
    make
}; 

function compile_gensub {
    echo "Compiling gensub $1 as support for base $2."
    base="$(pwd)/bases/$2"
    support="$base/support"
    dest="$support/gensub/$1"

    fname="genSubV$1.tar.gz"
    mkdir -p src/gensub
    cd src/gensub
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
    EPICS_HOST_ARCH=$(src/epics-base/startup/EpicsHostArch)
    sed -i -e "s/^#INSTALL_LOCATION_APP.*/INSTALL_LOCATION_APP=$(echo $dest | sed -e 's/\//\\\//g')/" configure/RELEASE    
    sed -i -e "s/EPICS_BASE=.*/EPICS_BASE=$(echo $base | sed -e 's/\//\\\//g')/" configure/RELEASE    
    sed -i -e "s/^\(CROSS_COMP.*\)/#\1/" configure/CONFIG    
    make
    rm -rf $1
};

function compile_cyusbdevsup {
    url="git@baltig.infn.it:epicscs/cyusbdevsup.git"
    dest="$support/cyusbdevsup/$1"
    if ! prepare_git_src $url 'cyusbdevsup' $1; then
        return 1
    fi

    cd src/cyusbdevsup
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    set_release_par 'EPICS_BASE' $base
    set_release_par 'ASYN' "$support/asyn/R4-33"
        
    #sed -i -e "s/#INSTALL_LOCATION=.*/INSTALL_LOCATION=$(echo $dest | sed -e 's/\//\\\//g' )/" configure/CONFIG_SITE    
    #sed -i -e "s/^EPICS_BASE=.*/EPICS_BASE=$(echo $base | sed -e 's/\//\\\//g')/" configure/RELEASE    
    #sed -i -e "s/^ASYN.*/ASYN=$(echo $asyn | sed -e 's/\//\\\//g')/" configure/RELEASE    
    make distclean
    make
};


function compile_motor {
    url='https://github.com/epics-modules/motor'
    dest="$support/motor/$1"
    if ! prepare_git_src $url 'motor' $1; then
        return 1
    fi
    cd src/motor
    set_release_par 'EPICS_BASE' $base
    set_release_par 'ASYN' "$support/asyn/R4-33"
    set_release_par 'SUPPORT' $support
    set_dep 'BUSY' 'R1-7'
    set_dep 'IPAC' '2.15'
    disable_release_par 'SNCSEQ'
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest

    make distclean
    make

};


function compile_ipac {
    url="https://github.com/epics-modules/ipac.git"
    dest="$support/ipac/$1"
    if ! prepare_git_src $url 'ipac' $1; then
        return 1
    fi
    cd src/ipac

    set_release_par 'EPICS_BASE' $base
    set_release_par 'SUPPORT' $support
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest

#    sed -i -e "s/EPICS_BASE=.*/EPICS_BASE=$(echo $base | sed -e 's/\//\\\//g')/" config/RELEASE    
#    echo "INSTALL_LOCATION_APP=$dest" >> config/RELEASE
    make distclean
    make
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
    url='https://github.com/epics-modules/calc.git'
    dest="$support/calc/$1"
    if ! prepare_git_src $url 'calc' $1; then
        return 1
    fi
    cd src/calc
    set_release_par 'EPICS_BASE' $base
    set_release_par 'SUPPORT' $support
    disable_release_par 'SSCAN'
    disable_release_par 'SNCSEQ'
    set_release_par 'INSTALL_LOCATION_APP' $dest    
    make

}



function compile_beckmotor {
    url="git@baltig.infn.it:epicscs/BeckMotor_EPICS.git"
    dest="$support/beckmotor/$1"
    if ! prepare_git_src $url 'beckmotor' $1; then
        return 1
    fi
    cd src/beckmotor
    set_release_par 'EPICS_BASE' $base
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    set_dep 'ASYN' 'R4-33'    
    set_dep 'MOTOR' 'R6-10' 
    make distclean
    make 
}

function compile_modbus {
    url="https://github.com/epics-modules/modbus.git"
    dest="$support/modbus/$1"
    if ! prepare_git_src $url 'modbus' $1; then
        return 1
    fi
    cd src/modbus
    set_release_par 'EPICS_BASE' $base
    set_release_par 'SUPPORT' $support
    set_dep 'ASYN' 'R4-33'
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    make distclean
    make
}

function compile_autosave {
    url="https://github.com/epics-modules/autosave.git"
    dest="$support/autosave/$1"
    if ! prepare_git_src $url 'autosave' $1; then
        return 1
    fi
    cd src/autosave
    set_release_par 'EPICS_BASE' $base
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    make distclean
    make
}



function compile_busy {
    url="https://github.com/epics-modules/busy.git"
    dest="$support/busy/$1"
    if ! prepare_git_src $url 'busy' $1; then
        return 1
    fi
    cd src/busy
    set_release_par 'EPICS_BASE' $base
    set_release_par 'SUPPORT' $support
    set_dep 'AUTOSAVE' 'R5-8'
    set_dep 'ASYN' 'R4-33'
    disable_release_par 'BUSY'
    set_config configure/CONFIG_SITE 'INSTALL_LOCATION' $dest
    make distclean
    make
}





# USAGE:
# ./compile.sh module version [base]
#   base - the module to be compiled
#   rel - the version of the module
#   bver - the base version, optional when compiling the base



src="/opt/epics/Modules/v3.15.5/" #"/usr/src/epics/"
base="$src/base/"
#echo "BASE $base"
support="$src/support"

## check parameters are 3 or 2 if the first one is base
if [ "$#" -ne 3 ]; then
    if [ "$#" -ne 2 ] || [ "$1" != "base" ]; then
        echo "Illegal number of parameters"
        echo "USAGE: $0 module version [base]"
        echo "     module   - the module to be compiled"
        echo "     version  - the version of the module"
        echo "     base     - the base version, optional when compiling the base"
        exit 1
    fi
fi

module=$1
version=$2
against=$3

if [ ! -d $src ]; then
    echo "Installing source folder"
    if ! sudo install -d -o $(whoami) -g $(id -n -g $(whoami)) -m 775 $src; then
        exit 1
    fi
fi

if [ "$cmd" != "base" ]; then
    arch=$($base/startup/EpicsHostArch)
fi


case $module in 
    base)
        compile_base $version
        ;;

    asyn)
        compile_asyn $version
        ;;


    gensub)
        compile_gensub $@
        ;;

    motor)
        compile_motor $rel   
        ;;

    ipac)
        compile_ipac $rel    
        ;;

    cyusbdevsup)
        compile_cyusbdevsup $rel
        ;; 
    
    streamdevice)
        compile_streamdevice $@
        ;;

    calc)
        compile_calc $rel
        ;;

    beckmotor)
        compile_beckmotor $rel
        ;;

    modbus)
        compile_modbus $rel
        ;;

    autosave)
        compile_autosave $rel
        ;;
    
    busy)
        compile_busy $rel
        ;;



         

esac




