unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Spin, EditBtn,
  uRemotes, process, LMessages, Menus, LCLType, ActnList;

const
  WMU_MOUNT_NEXT = WM_USER + 1;

type

  { TfmMain }

  TfmMain = class(TForm)
    PageControl1: TPageControl;
    tsConnection: TTabSheet;
    tsStatus: TTabSheet;
    ImageList1: TImageList;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    tmrStatusUpdate: TTimer;
    Button3: TButton;
    TrayIcon1: TTrayIcon;
    Button4: TButton;
    Label1: TLabel;
    edActName: TEdit;
    Label2: TLabel;
    edActHost: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    edActUsername: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    edActAuthPassword: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    edActOptions: TEdit;
    cbActAuth: TComboBox;
    seActPort: TSpinEdit;
    feActSecKey: TFileNameEdit;
    Label9: TLabel;
    cbActPath: TComboBox;
    meInfoStart: TMemo;
    Label10: TLabel;
    lbInfoPID: TLabel;
    Label11: TLabel;
    cbActDrive: TComboBox;
    Panel2: TPanel;
    lvDefs: TListView;
    Panel3: TPanel;
    Button5: TButton;
    Button6: TButton;
    cbActAutomount: TCheckBox;
    Button7: TButton;
    pmTray: TPopupMenu;
    miShow: TMenuItem;
    miStartMount: TMenuItem;
    miExit: TMenuItem;
    acMain: TActionList;
    acRemoteMount: TAction;
    acRemoteUnmount: TAction;
    acExploreTarget: TAction;
    acRemoteSaveChanges: TAction;
    acRemoteAdd: TAction;
    acRemoteRemove: TAction;
    acRemoteCopy: TAction;
    acTrayShow: TAction;
    acTrayBeginMount: TAction;
    acExit: TAction;
    pmList: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    N1: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    tsGlobalSettings: TTabSheet;
    Label12: TLabel;
    cbSSHFSExe: TComboBox;
    lbSSHFSInfo: TLabel;
    Panel4: TPanel;
    btnGlobalSave: TButton;
    btnGlobalUndo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvDefsData(Sender: TObject; Item: TListItem);
    procedure lvDefsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure tmrStatusUpdateTimer(Sender: TObject);
    procedure cbActDriveDropDown(Sender: TObject);
    procedure cbActAuthSelect(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure cbSSHFSExeChange(Sender: TObject);
    procedure btnGlobalSaveClick(Sender: TObject);
    procedure btnGlobalUndoClick(Sender: TObject);
    procedure cbSSHFSExeEnter(Sender: TObject);
    procedure cbSSHFSExeDropDown(Sender: TObject);
    procedure lvDefsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure acMainUpdate(AAction: TBasicAction; var Handled: Boolean);
    procedure acRemoteAddExecute(Sender: TObject);
    procedure acRemoteRemoveExecute(Sender: TObject);
    procedure acRemoteCopyExecute(Sender: TObject);
    procedure acRemoteSaveChangesExecute(Sender: TObject);
    procedure acRemoteMountExecute(Sender: TObject);
    procedure acRemoteUnmountExecute(Sender: TObject);
    procedure acExploreTargetExecute(Sender: TObject);
    procedure acExitExecute(Sender: TObject);
    procedure acTrayShowExecute(Sender: TObject);
    procedure acTrayBeginMountExecute(Sender: TObject);
  private
    fRemotes: TRemoteList;
    fExe: string;
    fActiveSelected: TRemote;
    procedure UpdateEditSelection(NewSel: TRemote);
    procedure RemoteMount(aRemote: TRemote);
    procedure RemotesChanged;
    procedure StartupActions;
    procedure WMUMountNext(var msg: TLMessage); message WMU_MOUNT_NEXT;
  public

  end;

var
  fmMain: TfmMain;

implementation

uses
  LCLIntf, FileUtil, uConfig;

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCreate(Sender: TObject);
var
  ini: TIniFile;
begin
  TrayIcon1.Icon:= Application.Icon;
  fRemotes:= TRemoteList.Create;
  ini:= OpenIniFile;
  try
    fExe:= ini.ReadString('Config', 'Exe', '');
    fRemotes.LoadFromIni(ini);
  finally
    FreeAndNil(ini);
  end;
  btnGlobalUndo.Click;
  fActiveSelected:= nil;
  lvDefs.Items.Count:= fRemotes.Count;
  lvDefs.Selected:= nil;
  lvDefsSelectItem(nil, nil, False);
  PageControl1.ActivePageIndex:= 0;
  StartupActions;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fRemotes);
end;

procedure TfmMain.StartupActions;
var
  i: Integer;
begin
  for i:= 1 to ParamCount do begin
    case ParamStr(i) of
      '/min': begin
        //PostMessage(Handle, LM_SYSCOMMAND, SC_MINIMIZE, 0);
        Application.ShowMainForm:= False;
      end;
      '/automount': PostMessage(Handle, WMU_MOUNT_NEXT, 0, 0);
    end;
  end;
end;

procedure TfmMain.WMUMountNext(var msg: TLMessage);
var
  idx: Integer;
  r: TRemote;
begin
  idx:= msg.wParam;
  if idx >= fRemotes.Count then
    Exit;

  r:= fRemotes[idx];
  if (r.Status in [rsNone]) and r.AutoMount then begin
    RemoteMount(r);
    PostMessage(Handle, WMU_MOUNT_NEXT, idx + 1, 0);
  end;
end;

procedure TfmMain.lvDefsData(Sender: TObject; Item: TListItem);
var
  r: TRemote;
begin
  if (Item.Index<0) or (Item.Index>=fRemotes.Count) then
    exit;
  r:= fRemotes[Item.Index];
  Item.Caption:= r.GetDriveStr;
  Item.SubItems.Add(r.GetConnectStr(True));
  Item.ImageIndex:= Ord(r.Status);
end;

procedure TfmMain.lvDefsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if lvDefs.ItemIndex >= 0 then
    UpdateEditSelection(fRemotes[lvDefs.ItemIndex])
  else
    UpdateEditSelection(nil);
end;

procedure TfmMain.UpdateEditSelection(NewSel: TRemote);
begin
  if Assigned(NewSel) then begin
    if fActiveSelected = NewSel then
      Exit;
    edActName.Text:= NewSel.Name;
    edActHost.Text:= NewSel.Host;
    seActPort.Value:= NewSel.Port;
    edActUsername.Text:= NewSel.User;
    cbActAuth.ItemIndex:= ord(NewSel.Auth);
    cbActAuthSelect(nil);
    feActSecKey.FileName:= NewSel.AuthSecKey;
    edActAuthPassword.Text:= NewSel.AuthPassword;
    cbActPath.Text:= NewSel.Path;
    cbActDrive.Text:= NewSel.Drive;
    edActOptions.Text:= NewSel.Options;
    cbActAutomount.Checked:= NewSel.AutoMount;
  end else begin
    edActName.Text:= '';
    edActHost.Text:= '';
    seActPort.Value:= 22;
    edActUsername.Text:= '';
    cbActAuth.ItemIndex:= 0;
    feActSecKey.FileName:= '';
    edActAuthPassword.Text:= '';
    cbActPath.Text:= '';
    cbActDrive.Text:= '';
    edActOptions.Text:= '';
    cbActAutomount.Checked:= False;
  end;
  fActiveSelected:= NewSel;
end;

procedure TfmMain.RemoteMount(aRemote: TRemote);

  function tocygdrive(fn: string): string;
  begin
    fn:= ExpandFileName(fn);
    Result:= '/cygdrive/' + LowerCase(fn[1]) + fn.Substring(2).Replace(PathDelim, '/');
  end;

var
  proc: TProcess;
  tooldir: string;
  BytesRead: Integer;
  OutputLength: integer;
  OutputString: String;
  tstart: LongWord;
  sshfspid: SizeUInt;
begin
  if not FileExists(fExe) then begin
    MessageDlg('SSHFS binary not present, please check settings!', mtError, [mbOK], 0);
    PageControl1.ActivePage:= tsStatus;
    exit;
  end;

  tooldir:= ExtractFilePath(ParamStr(0)) + 'lib\';

  proc:= TProcess.Create(nil);
  try
    Screen.Cursor:= crHourGlass;
    proc.Options:= [poUsePipes, poStderrToOutPut, poNewProcessGroup, poNoConsole];
    // Use our provided env.exe, but in the target's dir - means it loads *their* cygwin1.dll
    proc.Executable:= tooldir + 'env.exe';
    proc.CurrentDirectory:= ExtractFileDir(fExe);
    // pass all env variables we might need
    proc.Parameters.AddStrings([
     '-',
     'PATH='+tocygdrive(tooldir)+':'+tocygdrive(ExtractFilePath(fExe)),
     'DISPLAY=1',
     'SSH_ASKPASS=print_pass.exe',
     'SSHFS_AUTH_PASSPHRASE=' + aRemote.AuthPassword
    ]);
    // the actuall sshfs process
    proc.Parameters.AddStrings([
     tocygdrive(fExe),
     aRemote.GetConnectStr,
     aRemote.Drive,
     '-ovolname='+aRemote.Name,
     '-ossh_command=ssh_ap.exe -v',
     '-f',
     // do not attempt loading user profile data
     '-F/dev/null', '-oIdentitiesOnly=yes',
     // make message reproducible
     '-oUserKnownHostsFile=/dev/null', '-oStrictHostKeyChecking=no',
     // remap for write permissions
     '-ouid=-1,gid=-1', '-oidmap=user', '-oumask=000', '-ocreate_umask=000'
    ]);
    // port is not part of the connect string
    if aRemote.Port<>22 then
      proc.Parameters.Add('-p%d', [aRemote.Port]);
    // authentication
    case aRemote.Auth of
      amPassword: begin
        proc.Parameters.AddStrings([
          '-oPreferredAuthentications=password'
        ]);
      end;
      amPubkey: begin
        proc.Parameters.AddStrings([
          '-oPreferredAuthentications=publickey',
          '-oIdentityFile='+aRemote.AuthSecKey.Replace('\','\\')
        ]);
      end;
    end;
    // user options last (allow override)
    proc.Parameters.AddDelimitedText(aRemote.Options);
    // Execute and capture PID as soon as we can
    proc.Execute;
    aRemote.PID:= proc.ProcessID;
    // wait and see what happens
    proc.CloseInput;
    OutputLength:= 0;
    OutputString:= '';
    BytesRead:= 0;
    tstart:= GetTickCount64;
    while proc.Running and (GetTickCount64 - tstart < 5000) do begin
      proc.ReadInputStream(proc.Output,BytesRead,OutputLength,OutputString,1);
      if Pos('has been started', OutputString)>0 then
        break;
      Application.ProcessMessages;
    end;
    proc.ReadInputStream(proc.Output,BytesRead,OutputLength,OutputString,1);
    // Disconnect pipes
    proc.CloseOutput;
    proc.CloseStderr;
    aRemote.InfoStart:= Copy(OutputString, 1, BytesRead);
//    Writeln('Mount: new parent PID=', aRemote.PID);
//    WriteLn('Output:');
//    Writeln(aRemote.InfoStart);

    // if everything worked up to here, retarget our tracking to the subprocess
    // this also cleans up the cleartext password leak in argv of /bin/env
    if FindSubprocess(aRemote.PID, ExtractFileName(fExe), sshfspid) then begin
//      Writeln('Mount: new child PID=', sshfspid);
      if KillProcess(aRemote.PID) then begin
         aRemote.PID:= sshfspid;
//         Writeln('Mount: now tracking child process');
      end;
    end;
  finally
    Screen.Cursor:= crDefault;
    FreeAndNil(proc);
  end;
  RemotesChanged;
  aRemote.UpdateStatus;
end;

procedure TfmMain.RemotesChanged;
var
  ini: TIniFile;
begin
  ini:= OpenIniFile;
  try
    fRemotes.SaveToIni(ini);
  finally
    FreeAndNil(ini);
  end;
end;

procedure TfmMain.tmrStatusUpdateTimer(Sender: TObject);
const
  LPAD = '     ';
var
  r: TRemote;
  mounted: string;
begin
  mounted:= '';
  for r in fRemotes do begin
    if r.Status = rsConnected then
      mounted+= LPAD + r.GetDriveStr + sLineBreak;
  end;
  if mounted = '' then
    mounted:= LPAD + 'none';
  TrayIcon1.Hint:= Caption + sLineBreak + 'Mounted Drives: ' + sLineBreak + mounted;
  lvDefs.Refresh;
end;

procedure TfmMain.cbActAuthSelect(Sender: TObject);
begin
  feActSecKey.Enabled:= TRemoteAuthMethod(cbActAuth.ItemIndex) in [amPubkey];
  edActAuthPassword.Enabled:= TRemoteAuthMethod(cbActAuth.ItemIndex) in [amPassword, amPubkey];
end;

procedure TfmMain.cbActDriveDropDown(Sender: TObject);
var
  d: Char;
  sel: String;
begin
  sel:= cbActDrive.Text;
  cbActDrive.Clear;
  for d in GetFreeDriveLetters do
    cbActDrive.Items.Add(d + ':');
  cbActDrive.Text:= sel;
end;

procedure TfmMain.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then begin
    WindowState:= wsNormal;
    Hide;
    ShowInTaskBar:= stNever;
  end;
end;

procedure TfmMain.btnGlobalSaveClick(Sender: TObject);
begin
  fExe:= cbSSHFSExe.Text;
  with OpenIniFile do try
    WriteString('Config', 'Exe', fExe);
  finally
    Free;
  end;
end;

procedure TfmMain.btnGlobalUndoClick(Sender: TObject);
begin
  cbSSHFSExe.Text:= fExe;
  cbSSHFSExeChange(nil);
end;

procedure TfmMain.cbSSHFSExeEnter(Sender: TObject);
begin
  cbSSHFSExe.Items.Clear;
end;

function GetSSHFSVersion(candidate: string): string;
var
  outp: string;
begin
  Result:= '';
  if FileExists(candidate) and SameFileName(ExtractFileName(candidate), 'sshfs.exe') and
     RunCommandIndir(ExtractFileDir(candidate), candidate, ['-V'], outp, [poNoConsole], swoHIDE) then
    Result:= outp.Trim.Replace(#13,'').Replace(#10, ' ');
end;

procedure TfmMain.cbSSHFSExeDropDown(Sender: TObject);
  procedure Test(guess: string);
  var
    v: string;
  begin
    if cbSSHFSExe.Items.IndexOf(guess)>= 0 then
      Exit;
    v:= GetSSHFSVersion(guess);
    if v > '' then
      cbSSHFSExe.Items.Add(guess);
  end;

begin
  if cbSSHFSExe.Items.Count = 0 then begin
    Test(ExtractFilePath(ParamStr(0)) + 'sshfs-win\sshfs.exe');
    Test(ConcatPaths([GetEnvironmentVariable('ProgramW6432'),'SSHFS-Win\bin\sshfs.exe']));
    Test(ConcatPaths([GetEnvironmentVariable('ProgramFiles'),'SSHFS-Win\bin\sshfs.exe']));
  end;
end;

procedure TfmMain.lvDefsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  itm: TListItem;
  OriginalHint, h: String;
  r: TRemote;
begin
  itm:= lvDefs.GetItemAt(X, Y);
  OriginalHint:= lvDefs.Hint;
  if not Assigned(itm) then
    lvDefs.Hint:= 'nix'
  else begin
    h:= itm.Caption;
    r:= fRemotes[itm.Index];
    h += sLineBreak + 'Status: ' + StatusNames[r.Status];
    if r.PID > 0 then
      h += sLineBreak + 'Process: ' + IntToStr(r.PID);
    lvDefs.Hint:= h;
  end;
  if lvDefs.Hint <> OriginalHint then
    Application.CancelHint;
end;

procedure TfmMain.cbSSHFSExeChange(Sender: TObject);
var
  outp: string;
begin
  lbSSHFSInfo.Caption:= '<invalid>';
  outp:= GetSSHFSVersion(cbSSHFSExe.Text);
  if outp>'' then
    lbSSHFSInfo.Caption:= outp;
end;

procedure TfmMain.acMainUpdate(AAction: TBasicAction; var Handled: Boolean);
var
  pn: String;
begin
  tsConnection.Enabled:= Assigned(fActiveSelected);
  acRemoteMount.Enabled:= Assigned(fActiveSelected) and (fActiveSelected.Status in [rsNone]);
  acRemoteUnmount.Enabled:= Assigned(fActiveSelected) and (fActiveSelected.Status in [rsConnected]);
  acExploreTarget.Enabled:= Assigned(fActiveSelected) and (fActiveSelected.Status in [rsDriveTaken, rsConnected]);
  acRemoteRemove.Enabled:= Assigned(fActiveSelected) and (fActiveSelected.Status in [rsNone, rsDriveTaken]);
  acRemoteCopy.Enabled:= Assigned(fActiveSelected);


  if Assigned(fActiveSelected) then begin
    meInfoStart.Lines.Text:= fActiveSelected.InfoStart;
    lbInfoPID.Caption:= IntToStr(fActiveSelected.PID);
    if GetProcessInfo(fActiveSelected.PID, pn) = STILL_ACTIVE then
      lbInfoPID.Caption:= lbInfoPID.Caption + ' <...' + Copy(pn, Length(pn) - 42) + '>';
  end else begin
    meInfoStart.Clear;
    lbInfoPID.Caption:= '';
  end;
end;

procedure TfmMain.acRemoteAddExecute(Sender: TObject);
var
  r: TRemote;
begin
  r:= TRemote.Create;
  r.Name:= Format('Connection %d', [fRemotes.Count + 1]);
  fRemotes.Add(r);
  RemotesChanged;
  lvDefs.Items.Count:= fRemotes.Count;
  lvDefs.ItemIndex:= lvDefs.Items.Count - 1;
end;

procedure TfmMain.acRemoteRemoveExecute(Sender: TObject);
var
  todel: TRemote;
begin
  todel:= fActiveSelected;
  lvDefs.ItemIndex:= -1;
  fRemotes.Remove(todel);
  RemotesChanged;
  lvDefs.Items.Count:= fRemotes.Count;
end;

procedure TfmMain.acRemoteCopyExecute(Sender: TObject);
var
  r: TRemote;
begin
  r:= TRemote.Create;
  r.CopyFrom(fActiveSelected);
  r.Name:= Format('Connection %d', [fRemotes.Count + 1]);
  fRemotes.Add(r);
  RemotesChanged;
  lvDefs.Items.Count:= fRemotes.Count;
  lvDefs.ItemIndex:= lvDefs.Items.Count - 1;
end;

procedure TfmMain.acRemoteSaveChangesExecute(Sender: TObject);
begin
  fActiveSelected.Name:= edActName.Text;
  fActiveSelected.Host:= edActHost.Text;
  fActiveSelected.Port:= seActPort.Value;
  fActiveSelected.User:= edActUsername.Text;
  fActiveSelected.Auth:= TRemoteAuthMethod(cbActAuth.ItemIndex);
  fActiveSelected.AuthSecKey:= feActSecKey.FileName;
  fActiveSelected.AuthPassword:= edActAuthPassword.Text;
  fActiveSelected.Path:= cbActPath.Text;
  fActiveSelected.Drive:= cbActDrive.Text;
  fActiveSelected.Options:= edActOptions.Text;
  fActiveSelected.AutoMount:= cbActAutomount.Checked;
  RemotesChanged;
  lvDefs.Refresh;
end;

procedure TfmMain.acRemoteMountExecute(Sender: TObject);
begin
  if fActiveSelected.Status <> rsNone then
    Exit;

  RemoteMount(fActiveSelected);
end;

procedure TfmMain.acRemoteUnmountExecute(Sender: TObject);
begin
  if fActiveSelected.Status <> rsConnected then
    Exit;
  if KillProcessTree(fActiveSelected.PID, 0) then begin
    fActiveSelected.PID:= 0;
  end;
  RemotesChanged;
  fActiveSelected.UpdateStatus;
end;

procedure TfmMain.acExploreTargetExecute(Sender: TObject);
begin
  OpenDocument(fActiveSelected.Drive);
end;

procedure TfmMain.acExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfmMain.acTrayShowExecute(Sender: TObject);
begin
  ShowInTaskBar:= stDefault;
  Show;
end;

procedure TfmMain.acTrayBeginMountExecute(Sender: TObject);
begin
  PostMessage(Handle, WMU_MOUNT_NEXT, 0, 0);
end;


end.

