# epicsmng

## A tool to easily download and install epics modules

_epicsmng_ will read a configuration file and install all the listed modules with the required version. This works by downloading the source, performing a git fetch and git checkout to the correct version. After that the modules are configured and built against each another.

For example, given the following configuration ```myconf.conf```:

```
base = v3.15.5
asyn = R4-33
```

by running 

```
epicsmng makemodules myconf.conf
```

both will be downloaded, built and installed, with asyn configured to be use that specific version of base. Inter-depencecies are automatically resolved.

The compiled binaries, libraries, dbd etc. are installed in the ```./modules/myconf/``` folder, with respect to the path where the script has been executed.

## Installation

1) Download repository archive or git clone it
2) Unpack it if required
3) ```cd epicsmng```
4) ```sudo sh install.sh```
5) Enjoy!

To remove it: ```sudo sh uninstall.sh```

## Commands

1) ```epicsmng makemodules [-C <path>] [-j<n>] [-v]  <conf_file>```
2) ```epicsmng cleanmodules [-C <path>]  <conf_file>```
3) ```epicsmng configureioc [-C <path>]  <conf_file>```
4) ```epicsmng listmodules```
5) ```epicsmng createconfig <destination_file>```