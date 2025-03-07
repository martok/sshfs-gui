unit uRemotes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, fgl, JwaWindows;


type
  TRemoteList = class;

  TRemoteStatus = (
    rsNone,                         // all clear, no leftovers
    rsDriveTaken,                   // drive letter is occupied and PID does not hint at corresponding process
    rsDriveMissing,                 // drive letter is unoccupied but PID is valid
    rsConnected                     // successfully connected, PID valid
  );

  TRemoteAuthMethod = (
    amPassword,
    amPubkey
  );

  { TRemote }

  TRemote = class
  private
    fStatus: TRemoteStatus;
  public
    // saved attribs
    Name: String;
    Drive: String;
    Host: String;
    Port: integer;
    User: String;
    Path: String;
    Auth: TRemoteAuthMethod;
    AuthSecKey: String;
    AuthPassword: String;
    Options: String;
    AutoMount: Boolean;
  public
    // ephemeral
    InfoStart: String;
  public
    PID: SizeUInt;
    function Status: TRemoteStatus;
    function GetConnectStr(IncludePort: boolean=false): String;
    function GetDriveStr: String;
    procedure UpdateStatus;
    constructor Create;
    procedure ReadSection(ini: TIniFile; section: String);
    procedure WriteSection(ini: TIniFile; section: String);
    procedure CopyFrom(Source: TRemote);
  end;

  { TRemoteList }

  TRemoteList = class(specialize TFPGObjectList<TRemote>)
  private
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure LoadFromIni(ini: TIniFile);
    procedure SaveToIni(ini: TIniFile);
  end;

const
  StatusNames: Array[TRemoteStatus] of String = (
    'Not mounted',
    'Drive already used',
    'Error: Drive missing',
    'Connected'
  );

const
  STILL_ACTIVE = JwaWindows.STILL_ACTIVE;

function GetProcessInfo(PID: SizeUInt; out ProcName: String): Integer;
function KillProcess(PID:SizeUInt; Status:integer = 0): boolean;
function KillProcessTree(PID: SizeUInt; Status: Integer = 0): Boolean;
function FindSubprocess(PID: SizeUInt; ProcessName: String; out ChildPID: SizeUInt): boolean;

function GetFreeDriveLetters: string;

function DPProtect(Data: TBytes): String;
function DPUnprotect(Encoded: String): TBytes;

implementation

function GetProcessInfo(PID: SizeUInt; out ProcName: String): Integer;
var
  hproc: HANDLE;
  ec: DWORD;
  buf: array[0..4096] of char;
begin
  ec:= 0;
  ProcName:= '';
  hproc:= OpenProcess(PROCESS_QUERY_INFORMATION, false, PID);
  if hproc = INVALID_HANDLE_VALUE then
    Exit(INVALID_HANDLE_VALUE);
  try
    // still active?
    if not GetExitCodeProcess(hproc, ec) then
      exit(INVALID_HANDLE_VALUE);
    Result:= ec;
    if ec = STILL_ACTIVE then begin
      GetProcessImageFileName(hproc, buf, Length(buf)-1);
      ProcName:= StrPas(buf);
    end;
  finally
    CloseHandle(hproc);
  end;
end;

function KillProcess(PID:SizeUInt; Status:integer = 0): boolean;
var
  hproc: HANDLE;
begin
  Result:= False;
  hproc:= OpenProcess(PROCESS_TERMINATE, false, PID);
  if hproc = INVALID_HANDLE_VALUE then
    Exit;
  try
//    Writeln('KillProcess ',PID);
    Result:= TerminateProcess(hproc, Status);
  finally
    CloseHandle(hproc);
  end;
end;

function KillProcessTree(PID: SizeUInt; Status: Integer = 0): Boolean;
var
  hSnap: HANDLE;
  pe: PROCESSENTRY32;
begin
  Result:= False;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  pe:= Default(PROCESSENTRY32);
  pe.dwSize:= SizeOf(pe);
  if Process32First(hSnap, pe) then begin
    repeat
      if pe.th32ParentProcessID = PID then begin
//        Writeln('KillProcessTree ',StrPas(pe.szExeFile),':',pe.th32ProcessID);
        if not KillProcessTree(pe.th32ProcessID, Status) then
          Exit(False);
      end;
    until not Process32Next(hSnap, pe);
    Result:= KillProcess(PID, Status);
  end;
end;

function FindSubprocess(PID: SizeUInt; ProcessName: String; out ChildPID: SizeUInt): boolean;
var
  hSnap: HANDLE;
  pe: PROCESSENTRY32;
begin
  Result:= False;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  pe:= Default(PROCESSENTRY32);
  pe.dwSize:= SizeOf(pe);
  if Process32First(hSnap, pe) then begin
    repeat
      if (pe.th32ParentProcessID = PID) and (pe.szExeFile = ProcessName) then begin
        ChildPID:= pe.th32ProcessID;
        Exit(True);
      end;
    until not Process32Next(hSnap, pe);
  end;
end;


function GetFreeDriveLetters: string;
var
  d: byte;
  bits: DWORD;
begin
  bits:= GetLogicalDrives;
  Result:= '';
  for d:= ord('A') to ord('Z') do begin
    if (bits and 1) = 0 then
      Result += Chr(d);
    bits:= bits shr 1;
  end;
end;

function DPProtect(Data: TBytes): String;
var
  blobin, blobout: DATA_BLOB;
  L: DWORD;
begin
  Result:= '';
  blobin.cbData:= Length(Data);
  blobin.pbData:= @Data[0];
  if CryptProtectData(@blobin, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @blobout) then begin
    L:= blobout.cbData * 4;
    SetLength(Result, L);
    if CryptBinaryToStringA(blobout.pbData, blobout.cbData, CRYPT_STRING_BASE64 or CRYPT_STRING_NOCR, @Result[1], L) then begin
      SetLength(Result, L);
      Result:= Result.Replace(#10, '');
    end else
      Result:= '';
    LocalFree(HLOCAL(blobout.pbData));
  end;
end;

function DPUnprotect(Encoded: String): TBytes;
var
  buf: TBytes;
  blobin, blobout: DATA_BLOB;
  L: DWORD;
begin
  Result:= nil;
  buf:= nil;
  L:= Length(Encoded);
  SetLength(buf, L);
  if CryptStringToBinaryA(@Encoded[1], Length(Encoded), CRYPT_STRING_BASE64, @buf[0], L, nil, nil) then begin
    blobin.cbData:= L;
    blobin.pbData:= @buf[0];
    if CryptUnprotectData(@blobin, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @blobout) then begin
      SetLength(Result, blobout.cbData);
      Move(blobout.pbData^, Result[0], Length(Result));
      LocalFree(HLOCAL(blobout.pbData));
    end;
  end;
end;

{ TRemote }

function TRemote.GetConnectStr(IncludePort: boolean = false): String;
begin
  Result:= User + '@' + Host;
  if IncludePort and (Port <> 22) then
    Result:= Result + '!' + Inttostr(Port);
  if Path > '' then
    Result:= Result + ':' + Path
  else
    Result:= Result + ':.';
end;

function TRemote.GetDriveStr: String;
begin
  Result:= Format('%s (%s)', [Name, Drive])
end;

function TRemote.Status: TRemoteStatus;
begin
  UpdateStatus;
  Result:= fStatus;
end;

procedure TRemote.UpdateStatus;
var
  drivepresent: boolean;
  a: UINT;
  pn: String;
begin
  a:= GetDriveType(PChar(Drive + DirectorySeparator));
  drivepresent:= a <> DRIVE_NO_ROOT_DIR;

  if PID > 0 then begin
    if GetProcessInfo(PID, pn) <> STILL_ACTIVE then
      PID:= 0;
  end;

  if PID > 0 then begin
    if drivepresent then begin
      fStatus:= rsConnected;
    end
    else
      fStatus:= rsDriveMissing;
  end else begin
    if drivepresent then
      fStatus:= rsDriveTaken
    else
      fStatus:= rsNone;
  end;
end;

constructor TRemote.Create;
begin
  inherited;
  Name:= '';
  Drive:= 'Z:';
  Host:= 'host';
  Port:= 22;
  User:= 'user';
  Path:= '.';
  PID:= 0;
  Auth:= amPassword;
  AuthPassword:= '';
  AuthSecKey:= '';
  Options:= '';
  AutoMount:= false;
end;

procedure TRemote.ReadSection(ini: TIniFile; section: String);
begin
  Name:= ini.ReadString(section, 'Name', '');
  Drive:= ini.ReadString(section, 'Drive', '');
  Host:= ini.ReadString(section, 'Host', '');
  Port:= ini.ReadInteger(section, 'Port', 22);
  User:= ini.ReadString(section, 'User', '');
  Path:= ini.ReadString(section, 'Path', '.');
  PID:= ini.ReadInteger(section, 'PID', 0);
  case ini.ReadString(section, 'Auth', 'password').ToLower of
    'password': Auth:= amPassword;
    'pubkey': Auth:= amPubkey;
  end;
  AuthPassword:= TEncoding.Default.GetAnsiString(DPUnprotect(ini.ReadString(section, 'AuthPassword', '')));

  AuthSecKey:= ini.ReadString(section, 'AuthSecKey', '');
  Options:= ini.ReadString(section, 'Options', '');
  AutoMount:= ini.ReadBool(section, 'AutoMount', false);
end;

procedure TRemote.WriteSection(ini: TIniFile; section: String);
begin
  ini.WriteString(section, 'Name', Name);
  ini.WriteString(section, 'Drive', Drive);
  ini.WriteString(section, 'Host', Host);
  ini.WriteInteger(section, 'Port', Port);
  ini.WriteString(section, 'User', User);
  ini.WriteString(section, 'Path', Path);
  ini.WriteInteger(section, 'PID', PID);
  case Auth of
    amPassword: ini.WriteString(section, 'Auth', 'password');
    amPubkey: ini.WriteString(section, 'Auth', 'pubkey');
  end;
  ini.WriteString(section, 'AuthPassword', DPProtect(TEncoding.Default.GetAnsiBytes(AuthPassword)));
  ini.WriteString(section, 'AuthSecKey', AuthSecKey);
  ini.WriteString(section, 'Options', Options);
  ini.WriteBool(section, 'AutoMount', AutoMount);
end;

procedure TRemote.CopyFrom(Source: TRemote);
var
  ini: TMemIniFile;
begin
  ini:= TMemIniFile.Create('');
  try
    Source.WriteSection(ini, 'A');
    ReadSection(ini, 'A');
    // PID should not be copied
    PID:= 0;
  finally
    FreeAndNil(ini);
  end;
end;

{ TRemoteList }

constructor TRemoteList.Create;
begin
  inherited Create(True);
end;

destructor TRemoteList.Destroy;
begin
  inherited Destroy;
end;

procedure TRemoteList.LoadFromIni(ini: TIniFile);
var
  i: Integer;
  sec: String;
  r: TRemote;
begin
  Clear;
  for i:= 0 to ini.ReadInteger('Config', 'Remotes', 0) - 1 do begin
    sec:= Format('Remote%d',[i]);
    r:= TRemote.Create;
    r.ReadSection(ini, sec);
    Add(r);
    r.UpdateStatus;
  end;
end;

procedure TRemoteList.SaveToIni(ini: TIniFile);
var
  i: Integer;
  sec: String;
  r: TRemote;
begin
  ini.WriteInteger('Config', 'Remotes', Count);
  for i:= 0 to Count - 1 do begin
    sec:= Format('Remote%d',[i]);
    r:= Items[i];
    r.WriteSection(ini, sec);
  end;
end;

end.

