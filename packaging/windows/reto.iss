; Inno Setup script of the Windows installer.
; Built by .github/workflows/build.yml from the package that
; tools/build-windows.sh stages in .windows/. Run with:
;   iscc /DAppVersion=0.1.1 /DAppArch=x64compatible /DArchName=x86_64 \
;     /DOutputDir=dist packaging\windows\reto.iss
; AppArch is x64compatible or arm64, ArchName is the one in the file name.

#define MyAppName "Reto"
#define MyAppExeName "reto.exe"
#define MyAppURL "https://github.com/ondratu/reto"
#define Stage "..\..\.windows"

[Setup]
AppId={{B3D5A1E7-6C42-4F0B-9A58-7E1D2C93F640}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher=Reto contributors
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
AppComments=View CSV files
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\reto.ico
LicenseFile=..\..\LICENSE
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} Setup
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\..\{#OutputDir}
OutputBaseFilename=cz.zeropage.Reto-windows-{#ArchName}-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#Stage}\installer\reto.ico
WizardImageFile={#Stage}\installer\wizard-large-202.png,{#Stage}\installer\wizard-large-336.png,{#Stage}\installer\wizard-large-430.png
WizardSmallImageFile={#Stage}\installer\wizard-small-58.png,{#Stage}\installer\wizard-small-97.png,{#Stage}\installer\wizard-small-124.png
DisableProgramGroupPage=yes
ChangesAssociations=yes
; GTK 4 needs Windows 10 or later.
MinVersion=10.0
ArchitecturesAllowed={#AppArch}
ArchitecturesInstallIn64BitMode={#AppArch}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#Stage}\Reto\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Stage}\installer\reto.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; IconFilename: "{app}\reto.ico"; Comment: "View CSV files"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; IconFilename: "{app}\reto.ico"; Comment: "View CSV files"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked
Name: "associate"; Description: "Open .&csv files with Reto (only where no other program is set yet)"; GroupDescription: "File associations:"

[Registry]
; Reto always registers itself as a program that can open .csv files: it
; shows up under "Open with" and in Settings > Default apps, but never
; replaces a program the user already chose. It may additionally become the
; default when the "associate" task is selected (see [Code]).
Root: HKA; Subkey: "Software\Classes\Reto.csv"; ValueType: string; ValueName: ""; ValueData: "CSV document"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Reto.csv\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\reto.ico"
Root: HKA; Subkey: "Software\Classes\Reto.csv\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\{#MyAppExeName}"" ""%1"""
Root: HKA; Subkey: "Software\Classes\.csv\OpenWithProgids"; ValueType: string; ValueName: "Reto.csv"; ValueData: ""; Flags: uninsdeletevalue

Root: HKA; Subkey: "Software\Reto"; ValueType: none; Flags: uninsdeletekeyifempty
Root: HKA; Subkey: "Software\Reto\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Reto\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "View CSV files"
Root: HKA; Subkey: "Software\Reto\Capabilities\FileAssociations"; ValueType: string; ValueName: ".csv"; ValueData: "Reto.csv"
Root: HKA; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: "Software\Reto\Capabilities"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "Launch Reto"; Flags: nowait postinstall skipifsilent

[Code]
{ Make Reto the default for .csv, but only if nothing is set yet - in HKCR,
  the merged per-user and per-machine view Windows itself reads. }
procedure SetDefaultIfUnset();
var
  Current: String;
begin
  if not RegQueryStringValue(HKCR, '.csv', '', Current) or (Current = '') then
    RegWriteStringValue(HKA, 'Software\Classes\.csv', '', 'Reto.csv');
end;

{ Undo SetDefaultIfUnset, leaving a default that another program set alone. }
procedure ClearDefaultIfOurs();
var
  Current: String;
begin
  if RegQueryStringValue(HKA, 'Software\Classes\.csv', '', Current) and
    (Current = 'Reto.csv') then
    RegDeleteValue(HKA, 'Software\Classes\.csv', '');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('associate') then
    SetDefaultIfUnset();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    ClearDefaultIfOurs();
end;
