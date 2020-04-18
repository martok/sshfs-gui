[*main*]
tasks=setup,all

[setup]
tool=env
SSHFS_WIN_UNPACK=C:\Dev\sshfs\sshfs-win-3.5.20024-x64\SourceDir\SSHFS-Win\bin

[all]
tasks=sshfs_gui,package

[sshfs_gui]
tool=lazbuild
project=sshfs_gui.lpi
mode=Release
build=clean

[package]
tool=zip
filename=sshfs-gui.zip
files=sshfs.files

[sshfs.files]
sshfs_gui.exe=
lib\env.exe=lib\
lib\ssh_ap.exe=lib\
lib\print_pass.exe=lib\
${SSHFS_WIN_UNPACK}\cyg*.dll=sshfs-win\
${SSHFS_WIN_UNPACK}\ssh*.exe=sshfs-win\
