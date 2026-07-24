[Setup]
AppId={{C7896C7A-3B64-47B2-B111-A5C0E2B8E5F9}
AppName=Norm
AppVersion=1.8.1
AppPublisher=Norm
DefaultDirName={autopf}\Norm
DefaultGroupName=Norm
OutputDir=installer\Output
OutputBaseFilename=Norm_v1.8.1_Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Norm"; Filename: "{app}\nota_ia_app.exe"
Name: "{autodesktop}\Norm"; Filename: "{app}\nota_ia_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\nota_ia_app.exe"; Description: "{cm:LaunchProgram,Norm}"; Flags: nowait postinstall skipifsilent
