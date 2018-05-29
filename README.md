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

+ ```epicsmng makemodules [-C <path>] [-j<n>] [-v]  <conf_file>```
   
   This command download modules sources, configures them and install in ```<path>/modules/<configname>``` where the path is the one specified by ```-C``` option (with default value the folder where the script is executed) and ```<configname>``` is the name of the configuration file. The ```-j``` option is used to enable multithread compilation, so ```-j5``` will use 5 thread to speed up the compilation process. The ```-v``` option let the user print more verbose output.

+ ```epicsmng cleanmodules [-C <path>]  <conf_file>```
   
   This command removes the compiled directories corresponding to a certain configuration file.

+ ```epicsmng configureioc [-C <path>]  <conf_file>```

   This command configures an ioc to use the specified configuration. The ioc is specified by its TOP folder path, via the ```-C``` option or by executing the script in the TOP folder. Then the file ```configure/RELEASE``` is set with the paths to the compiled modules, relative to the $(TOP) macro. Furthermore the file *App/src/Makefile (where * stands for each application installed in the ioc) is modified to add the corresponding dbd and libs.

+ ```epicsmng listmodules```

   This command lists the names of the available modules, that is the ones which will be accepted in the configuration file.

## How to use

1. Create a configuration file following the example.conf file and place it in the TOP directory of the corresponding ioc. The available modules can be listed via ```epicsmng listmodules```. The available versions are the git tag available on the git repositories of the modules, or exactly the version of the file to download for modules not available on git.

2. Execute ```epicsmng makemodules [-C <path>] [-j<n>] [-v]  <conf_file>``` in the ioc TOP folder.

3. Execute ```epicsmng configureioc [-C <path>]  <conf_file>``` in the ioc TOP folder.

4. Run ```make``` to compile the ioc as usual.

## Settings

It's possible to add a custom module to be compiled. This is achieved with the files located in ```~/.config/epicsmng/settings/```. Each file in this folder is imported during the execution of the script. If the module to be added can be found on a git repository the user simply has to define the following variables (example with asyn):

```
asyn_url='https://github.com/epics-modules/asyn.git'
asyn_requires="base"
asyn_optionals="sncseq ipac"
asyn_dbd="asyn.dbd drvAsynIPPort.dbd drvAsynSerialPort.dbd"
asyn_libs="asyn"
```
replacing asyn with the name of the module. The ```mymodule_url``` varibale is the url of the git repository to be cloned. The ```mymodule_requires``` are the modules required to compile it, that is the ones to be added to its ```configure/RELEASE``` file. The ```mymodule_optionals``` are modules that can be added to the ```configure/RELEASE``` when available but are not strictly necessary. The ```mymodule_dbd``` variable is a list of dbd files which the installed module will generate and that can be included by an application. The ```mymodule_libs``` variable is a list of libraries which the installed module will generate and that can be included by an application. The last two are used by ```configureioc``` command to correctly set the ```*App/src/Makefile``` file.

If the custom module is not a git repository, adding it is still possible but requires the definition of a custom function called ```compile_mymodule```. See the ```compile_sncseq``` inside ```epicsmng``` script for reference.