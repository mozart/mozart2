#include "MozartConfig.iss"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{992C8269-AE73-4377-88BE-D92459001279}
AppName=Mozart
AppVersion={#MozartVersion}
AppPublisher=Universite catholique de Louvain
AppPublisherURL=http://mozart.github.io/
AppSupportURL=http://mozart.github.io/
AppUpdatesURL=http://mozart.github.io/
DefaultDirName={pf}\Mozart
DefaultGroupName=Mozart
AllowNoIcons=yes
LicenseFile={#LicenseFile}
OutputDir=..\..
OutputBaseFilename={#OutputFilename}
Compression=lzma
SolidCompression=yes
WizardImageFile=mozartside.bmp
WizardSmallImageFile=mozartsmall.bmp
ChangesEnvironment=yes
#if TargetArch == "x86_64"
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"


[Components]
Name: "main"; Description: "Oz engine"; Types: full compact custom; Flags: fixed
#if EmacsIncluded == "ON"
Name: "emacs"; Description: "Emacs editor (for interactive Oz)"; Types: full
#endif


[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MozartFolder}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs; Components: main
#if TclIncluded == "ON"
Source: "{#TclFolder}\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs; Components: main
Source: "{#TclFolder}\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs; Components: main
#else
Source: "TclVer.bat"; Flags: dontcopy
#endif
#if EmacsIncluded == "ON"
Source: "{#EmacsFolder}\*"; DestDir: "{app}\opt"; Flags: ignoreversion recursesubdirs; Components: emacs
#endif

[Icons]
Name: "{group}\Mozart Programming Interface"; Filename: "{app}\bin\oz.exe"; IconFilename: "{app}\bin\oz.exe"
Name: "{group}\{cm:UninstallProgram,Mozart}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Mozart Programming Interface"; Filename: "{app}\bin\oz.exe"; Tasks: desktopicon; IconFilename: "{app}\bin\oz.exe"

[Registry]
#if EmacsIncluded == "ON"
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "OZEMACS"; ValueData: "{app}\opt\bin\runemacs.exe"; Flags: uninsdeletevalue; Components:emacs
#endif
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "OZHOME"; ValueData: "{app}"; Flags: uninsdeletevalue

[Code]
#include "ModifyPath.iss"

procedure CurStepChanged(CurStep: TSetupStep);
begin
  case CurStep of
    ssPostInstall:
      begin
        if IsAdminLoggedOn then                                  
          ModifyPath('{app}\bin', pmAddToEnd, psAllUsers)
        else
          ModifyPath('{app}\bin', pmAddToEnd, psCurrentUser);
      end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of
    usPostUninstall:
      begin
        if IsAdminLoggedOn then
          ModifyPath('{app}\bin', pmRemove, psAllUsers)
        else
          ModifyPath('{app}\bin', pmRemove, psCurrentUser);
      end;
  end;
end;

#if !(TclIncluded == "ON")
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  TmpFileName, ExecStdout: string;
  ResultCode: integer;
  Version : string;
begin
  ExtractTemporaryFile('TclVer.bat');
  TmpFileName := ExpandConstant('{tmp}') + '\tclver.txt';
  Exec(ExpandConstant('{tmp}') + '\TclVer.bat', '> "' + TmpFileName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  LoadStringFromFile(TmpFileName, ExecStdout);
  Version := Trim(ExecStdout);
  if Version = '0.0' then
    MsgBox('Tcl/Tk ' + {#NeededTclVersion} + ' seems not to be installed or not to be in your PATH. Mozart may not work properly.', mbError, MB_OK)
  else if not (Version = {#NeededTclVersion}) then
    MsgBox('Tcl/Tk ' + Version + ' was found, but version ' + {#NeededTclVersion} + ' is required. Mozart may not work properly.', mbError, MB_OK);
  DeleteFile(TmpFileName);
  Result := '';
end;
#endif
