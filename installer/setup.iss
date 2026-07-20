; Script de Inno Setup para Nota IA
; Requisitos: Inno Setup 6+ (https://jrsoftware.org/isdl.php)
;
; Instrucciones:
;   1. Compila Nota IA: flutter build windows --release
;   2. Abre este archivo en Inno Setup Compiler
;   3. Build → Compile (Ctrl+F9)
;   4. El instalador se generará en installer\Output\

#define MyAppName "Norm"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Creative Thinker"
#define MyAppURL "https://norm.app"
#define MyAppExeName "nota_ia_app.exe"

[Setup]
AppId={{B8F4A3D2-1C5E-4A7B-9D6F-8E2C1A3B5D7F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/support
AppUpdatesURL={#MyAppURL}/download
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=Output
OutputBaseFilename=NotaIA_Setup_v{#MyAppVersion}
Compression=lzma2/ultra
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequiredOverridesAllowed=dialog

; Elimina instalaciones previas antes de instalar
[InstallDelete]
Type: filesandordirs; Name: "{app}\*"

; Archivos a incluir (desde build/windows/x64/runner/Release/)
[Files]
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Accesos directos
[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

; Tarea opcional: icono en escritorio
[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"; Flags: checkedbydefault

; Ejecutar la app después de instalar
[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Ejecutar {#MyAppName}"; Flags: nowait postinstall skipifsilent

; Desinstalación limpia
[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: dirifempty; Name: "{app}"

; Personalización del mensaje de despedida
[Messages]
FinishedLabel=La instalación de %1 se ha completado. Puedes ejecutar la aplicación usando el acceso directo creado.
