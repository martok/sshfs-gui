[*main*]
tasks=setup,all

[setup]
tool=env
SSHFS_WIN_UNPACK=${realpath ..\sshfs-win-3.7.21011-x64\SourceDir\SSHFS-Win\bin}

[all]
tasks=sshfs_gui,package,package_rename

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
README.md=
lib\env.exe=lib\
lib\ssh_ap.exe=lib\
lib\print_pass.exe=lib\
${SSHFS_WIN_UNPACK}\cyg*.dll=sshfs-win\
${SSHFS_WIN_UNPACK}\ssh*.exe=sshfs-win\

[package_rename]
TOOL=CMD
for %%f in ( sshfs-gui.zip ) do set "tslocal=%%~tf"
for /F "tokens=1,2,3,4,5,6 delims=.:/ " %%a in ("%tslocal%") do set "ts=%%c%%b%%a-%%d%%e"
ren sshfs-gui.zip sshfs-gui-%ts%.zip
