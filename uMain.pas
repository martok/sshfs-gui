unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Spin, EditBtn,
  uRemotes, IniFiles, process;

type

  { TfmMain }

  TfmMain = class(TForm)
    PageControl1: TPageControl;
    tsCommon: TTabSheet;
    tsExtra: TTabSheet;
    ImageList1: TImageList;
    Panel1: TPanel;
    btnMount: TButton;
    btnUnmount: TButton;
    tmrStatusUpdate: TTimer;
    btnExplore: TButton;
    TrayIcon1: TTrayIcon;
    btnSaveChanges: TButton;
    ApplicationProperties1: TApplicationProperties;
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
    btnRemoteAdd: TButton;
    btnRemoteDel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvDefsData(Sender: TObject; Item: TListItem);
    procedure lvDefsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure btnMountClick(Sender: TObject);
    procedure btnUnmountClick(Sender: TObject);
    procedure tmrStatusUpdateTimer(Sender: TObject);
    procedure btnExploreClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure ApplicationProperties1Minimize(Sender: TObject);
    procedure btnSaveChangesClick(Sender: TObject);
    procedure cbActDriveDropDown(Sender: TObject);
    procedure btnRemoteAddClick(Sender: TObject);
    procedure btnRemoteDelClick(Sender: TObject);
    procedure cbActAuthSelect(Sender: TObject);
  private
    fRemotes: TRemoteList;
    fExe: string;
    fActiveSelected: TRemote;
    procedure UpdateActionButtons;
    procedure UpdateEditSelection(NewSel: TRemote);
    procedure RemoteMount(aRemote: TRemote);
  public

  end;

var
  fmMain: TfmMain;

implementation

uses
  LCLIntf;

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCreate(Sender: TObject);
begin
  TrayIcon1.Icon:= Application.Icon;
  fRemotes:= TRemoteList.Create;
  fRemotes.IniFile:= ChangeFileExt(ParamStr(0), '.ini');
  with TIniFile.Create(fRemotes.IniFile) do try
    fExe:= ExpandFileName(ReadString('Config', 'Exe', 'sshfs-win.exe'));
  finally
    Free;
  end;
  fActiveSelected:= nil;
  lvDefs.Items.Count:= fRemotes.Count;
  lvDefs.Selected:= nil;
  lvDefsSelectItem(nil, nil, False);
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fRemotes);
end;

procedure TfmMain.lvDefsData(Sender: TObject; Item: TListItem);
var
  r: TRemote;
begin
  if (Item.Index<0) or (Item.Index>=fRemotes.Count) then
    exit;
  r:= fRemotes[Item.Index];
  Item.Caption:= Format('%s (%s)', [r.Name, r.Drive]);
  Item.SubItems.Add(r.GetConnectStr);
  Item.ImageIndex:= Ord(r.Status);
end;

procedure TfmMain.lvDefsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin                 
  if lvDefs.ItemIndex >= 0 then
    UpdateEditSelection(fRemotes[lvDefs.ItemIndex])
  else
    UpdateEditSelection(nil);    
  UpdateActionButtons;        
end;

procedure TfmMain.UpdateActionButtons;
begin             
  PageControl1.Enabled:= Assigned(fActiveSelected);
  if Assigned(fActiveSelected) then begin         
    btnMount.Enabled:= fActiveSelected.Status in [rsNone];
    btnUnmount.Enabled:= fActiveSelected.Status in [rsConnected];
    btnExplore.Enabled:= fActiveSelected.Status in [rsDriveTaken, rsConnected];
  end;
  btnRemoteDel.Enabled:= Assigned(fActiveSelected) and (fActiveSelected.Status in [rsNone, rsDriveTaken]);
end;

procedure TfmMain.UpdateEditSelection(NewSel: TRemote);
var
  pn: String;
begin
  if fActiveSelected = NewSel then
    Exit;

  if Assigned(NewSel) then begin
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
    meInfoStart.Lines.Text:= NewSel.InfoStart;  
    lbInfoPID.Caption:= IntToStr(NewSel.PID);
    if GetProcessInfo(NewSel.PID, pn) = STILL_ACTIVE then
      lbInfoPID.Caption:= lbInfoPID.Caption + ' <...' + Copy(pn, Length(pn) - 42) + '>';
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
    meInfoStart.Clear; 
    lbInfoPID.Caption:= '';
  end;      
  fActiveSelected:= NewSel;
end;

procedure TfmMain.RemoteMount(aRemote: TRemote);
var
  proc: TProcess;
  BytesRead: Integer;
  OutputLength: integer;
  OutputString: String;
  tstart: LongWord;
  sshfspid: SizeUInt;
begin
  proc:= TProcess.Create(nil);
  try
    Screen.Cursor:= crHourGlass;
    proc.Options:= [poUsePipes, poStderrToOutPut, poNewProcessGroup, poNoConsole];
    proc.Executable:= fExe;
    proc.Environment.AddPair('PATH', '/bin');
    proc.Parameters.AddStrings([
     'cmd',
     format('%s@%s:%s',[aRemote.User, aRemote.Host, aRemote.Path]),
     aRemote.Drive,
     '-f',
     '-oUserKnownHostsFile=/dev/null', '-oStrictHostKeyChecking=no',
     '-oIdentitiesOnly=yes',
     '-ouid=-1,gid=-1', '-oidmap=user', '-oumask=000', '-ocreate_umask=000',
     '-ovolname='+aRemote.Name
    ]);
    if aRemote.Port<>22 then
      proc.Parameters.Add('-p%d', [aRemote.Port]);
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
    // encode modified ssh + pass_print
    proc.Parameters.Add('-ossh_command=/bin/env -'+
         ' PATH=/bin'+
         ' DISPLAY=1'+
         ' SSH_ASKPASS=/bin/print_pass'+
         ' SSHFS_AUTH_PASSPHRASE=%s'+
         ' /bin/ssh_ap', [aRemote.AuthPassword]);
    proc.Parameters.AddDelimitedText(aRemote.Options);
    proc.Execute;
    // Save PID as soon as possible
    aRemote.PID:= proc.ProcessID;
    // wait and see what happens:
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
    Writeln('Mount: new parent PID=', aRemote.PID);
    WriteLn('Output:');
    Writeln(aRemote.InfoStart);
    // if everything worked up to here, retarget our tracking to the subprocess
    // this also cleans up the cleartext password leak in argv of sshfs-win
    if FindSubprocess(aRemote.PID, 'sshfs.exe', sshfspid) then begin
      Writeln('Mount: new child PID=', sshfspid);
      if KillProcess(aRemote.PID) then begin
         aRemote.PID:= sshfspid;
         Writeln('Mount: now tracking child process');
      end;
    end;
  finally
    Screen.Cursor:= crDefault;
    FreeAndNil(proc);
  end;
  fRemotes.Save;
  aRemote.UpdateStatus;
end;

procedure TfmMain.btnMountClick(Sender: TObject);  
begin  
  if fActiveSelected.Status <> rsNone then
    Exit;

  RemoteMount(fActiveSelected);
end;

procedure TfmMain.btnUnmountClick(Sender: TObject);     
begin
  if fActiveSelected.Status <> rsConnected then
    Exit;
  if KillProcessTree(fActiveSelected.PID, 0) then begin
    fActiveSelected.PID:= 0;
  end;
  fRemotes.Save;
  fActiveSelected.UpdateStatus;
end;


procedure TfmMain.tmrStatusUpdateTimer(Sender: TObject);
var
  r: TRemote;
begin
  for r in fRemotes do begin
    r.UpdateStatus;
  end;
  lvDefs.Refresh;
  UpdateActionButtons;
end;

procedure TfmMain.btnExploreClick(Sender: TObject);
begin
  OpenDocument(fActiveSelected.Drive);
end;


procedure TfmMain.btnSaveChangesClick(Sender: TObject);
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
  fRemotes.Save;
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

procedure TfmMain.btnRemoteAddClick(Sender: TObject);
var
  r: TRemote;
begin
  r:= TRemote.Create;
  r.Name:= Format('Connection %d', [fRemotes.Count]);
  fRemotes.Add(r);
  fRemotes.Save;
  lvDefs.Items.Count:= fRemotes.Count;
  lvDefs.ItemIndex:= lvDefs.Items.Count - 1;
end;

procedure TfmMain.btnRemoteDelClick(Sender: TObject);
var
  todel: TRemote;
begin
  todel:= fActiveSelected;
  lvDefs.ItemIndex:= -1;
  fRemotes.Remove(todel);
  fRemotes.Save;
  lvDefs.Items.Count:= fRemotes.Count;
end;

procedure TfmMain.TrayIcon1Click(Sender: TObject);
begin
  Application.Restore;
end;

procedure TfmMain.ApplicationProperties1Minimize(Sender: TObject);
begin
  Hide;
end;


end.
