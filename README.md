# SSHFS-Gui

## Introduction

SSHFS-Gui for mounting and managing SSH drives using [SSHFS-Win](https://github.com/billziss-gh/sshfs-win).

Written in Lazarus and Freepascal.

## Installation

This program does not require installation (just extract to any directory). The configuration file is stored in the program directory, so it should be writable.

### Prerequisite

Install a recent version of [WinFsp](https://github.com/billziss-gh/winfsp/releases).

### Semi-Portable Releases

The release package (created with Buildfile) contains all of SSHFS-Win, no further installation is required.
Note that the configuration file is not fully portable due to the way passwords are stored.

### System-wide Installation

An already-installed sshfs-win (see the [installation instructions](https://github.com/billziss-gh/sshfs-win/blob/master/README.md)) can be used
by setting the path to that installation's `sshfs.exe` in the Settings page.

## Shims

SSHFS-Gui uses a number of shims, mainly to allow using sshfs with pubkeys with passphrase.

```
    env.exe                - env(1), cygwin
    ssh_ap.exe             - ssh(1), patched to use askpass with console
    print_pass.exe         - special askpass that forwards a password from environment var
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
