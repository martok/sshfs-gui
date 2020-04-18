# SSHFS-Gui

## Introduction
SSHFS-Gui for mounting and managing SSH drives using [SSHFS-Win](https://github.com/billziss-gh/sshfs-win).

Written in Lazarus and Freepascal.

## Installation

This program does not require installation (just extract to any directory). The configuration file is stored in the program directory, so it should be writable.

Nonetheless, there are two methods of setup.

### Installer based
First, install sshfs-win according to the [installation instructions](https://github.com/billziss-gh/sshfs-win/blob/master/README.md).

Then set the path to that `sshfs.exe` in the Extra page.

### Embedded / Semi-Portable

The package created with Buildfile contains all of SSHFS-Win, you only need to install [WinFsp](https://github.com/billziss-gh/winfsp/releases)

Note that the configuration file is not portable due to the way passwords are stored.

## Shims
SSHFS-Gui provides a number of shims, mainly to allow using sshfs with pubkeys with passphrase.
```
    env.exe                - env(1), cygwin
    ssh_ap.exe             - ssh(1), patched to use askpass with console
    print_pass.exe         - special askpass
```



## Commandline Options

Use these in a shortcut in Autostart etc.

```
    sshfs_gui [/min] [/automount]

        /min               Start minimized
        /automount         Perform automounting according to configuration
```


## Credits

Other GUIs:

 * https://mhogomchungu.github.io/sirikali/
 * https://github.com/evsar3/sshfs-win-manager

Other SSHFS's:
 * https://github.com/feo-cz/win-sshfs
