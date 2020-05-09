unit uConfig;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, IniFiles, LazFileUtils;

type
  TIniFile = IniFiles.TIniFile;

function GetSettingsFolder: string;
function OpenIniFile: TIniFile;

implementation

function GetSettingsFolder: string;
var
  tf: string;
  h: THandle;
begin
  // if portable is writable, use that
  Result:= ExtractFilePath(ParamStr(0));
  tf:= Result + 'sshfs_gui.ini';
  h:= FileOpen(tf, fmOpenReadWrite);
  if h = feInvalidHandle then
    h:= FileCreate(tf);
  if h <> feInvalidHandle then begin
    FileClose(h);
    Exit;
  end;
  // otherwise, use appdata
  Result:= GetAppConfigDir(False);
end;

function OpenIniFile: TIniFile;
begin
  Result:= TIniFile.Create(GetSettingsFolder + 'sshfs_gui.ini');
end;

function GetAppName: String;
begin
  Result:= 'SSHFS_GUI';
end;

function GetAppVendor: String;
begin
  Result:= '';
end;

initialization
  OnGetApplicationName:= @GetAppName;
  OnGetVendorName:= @GetAppVendor;

end.

