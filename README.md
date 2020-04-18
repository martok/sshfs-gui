# SSHFS-Gui

## Introduction
SSHFS-Gui for mounting and managing SSH drives using [SSHFS-Win](https://github.com/billziss-gh/sshfs-win).

Written in Lazarus and Freepascal.

## Installation

This program does not require installation (just extract to any directory). The configuration file is stored in the program directory,
so it should be writable.

Nonetheless, there are two methods of setup.

### Installer based
First, install sshfs-win according to the [installation instructions](https://github.com/billziss-gh/sshfs-win/blob/master/README.md).

### Shims
Copy these files to the directory where the `sshfs-win.exe` you intend to use resides:
```
    env.exe                - env(1)
    ssh_ap.exe             - ssh(1), patched to use askpass with console
    print_pass.exe         - special askpass
```

Then set the path to that `sshfs-win.exe` in the Extra page.

### Embedded / Semi-Portable

The package created with Buildfile contains all of SSHFS-Win, you only need to install [WinFsp](https://github.com/billziss-gh/winfsp/releases)

Note that the configuration file is not portable due to the way passwords are stored.

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
