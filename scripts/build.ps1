<#
.SYNOPSIS
  Script de compilación para Norm — produce APKs y ejecutable Windows en modo Release.
.DESCRIPTION
  - clean:   Elimina artefactos anteriores
  - logo:    Copia el logo desde C:\Src\logo\logo.png a las carpetas de assets
  - icons:   Regenera iconos de la app (requiere logo en assets/icon/logo.png)
  - splash:  Regenera splash screen (requiere logo en assets/splash/splash_logo.png)
  - apk:     Compila APK release con split-per-abi (x86_64, armeabi-v7a, arm64-v8a)
  - windows: Compila ejecutable Windows release
  - all:     Ejecuta todos los pasos anteriores en orden
#>

param(
  [ValidateSet('clean','logo','icons','splash','apk','windows','all')]
  [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Clean-Build {
  Write-Step "Limpiando artefactos anteriores"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "build\app\outputs"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "build\windows"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "build\flutter_assets"
  Write-Host "  ✓ Artefactos eliminados" -ForegroundColor Green
}

function Copy-Logo {
  Write-Step "Copiando logo desde C:\Src\logo\logo.png"
  $src = "C:\Src\logo\logo.png"
  if (-not (Test-Path $src)) { throw "Logo no encontrado en $src" }
  Copy-Item -Path $src -Destination "assets\icon\logo.png" -Force
  Copy-Item -Path $src -Destination "assets\splash\splash_logo.png" -Force
  Write-Host "  ✓ Logo copiado a assets/icon/ y assets/splash/" -ForegroundColor Green
}

function Build-Icons {
  Write-Step "Regenerando iconos de la aplicación"
  flutter pub run flutter_launcher_icons
  if ($LASTEXITCODE -ne 0) { throw "flutter_launcher_icons falló" }
  Write-Host "  ✓ Iconos generados" -ForegroundColor Green
}

function Build-Splash {
  Write-Step "Regenerando splash screen"
  flutter pub run flutter_native_splash:create
  if ($LASTEXITCODE -ne 0) { throw "flutter_native_splash falló" }
  Write-Host "  ✓ Splash generado" -ForegroundColor Green
}

function Build-Apk {
  Write-Step "Compilando APK release (split-per-abi)"
  flutter build apk --release --split-per-abi
  if ($LASTEXITCODE -ne 0) { throw "Build APK falló" }

  $outDir = "build\app\outputs\flutter-apk"
  Write-Host "`n  APKs generados en: $outDir" -ForegroundColor Yellow
  Get-ChildItem "$outDir\*.apk" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  ✓ $($_.Name) — ${size} MB" -ForegroundColor Green
  }
}

function Build-Windows {
  Write-Step "Compilando ejecutable Windows Release"
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw "Build Windows falló" }

  $outDir = "build\windows\x64\runner\Release"
  Write-Host "  ✓ Ejecutable compilado en: $outDir" -ForegroundColor Green

  # Calcular tamaño total
  $totalSize = (Get-ChildItem -Recurse "$outDir\*" | Measure-Object -Property Length -Sum).Sum
  $totalMB = [math]::Round($totalSize / 1MB, 2)
  Write-Host "  ✓ Tamaño total: ${totalMB} MB" -ForegroundColor Green

  Write-Host "`n  Para empaquetar con Inno Setup:" -ForegroundColor Yellow
  Write-Host "  1. Abre installer\setup.iss en Inno Setup" -ForegroundColor Yellow
  Write-Host "  2. Compila el instalador (Build → Compile)" -ForegroundColor Yellow
}

function Build-All {
  Clean-Build
  Copy-Logo
  Build-Icons
  Build-Splash
  Build-Apk
  Build-Windows
}

switch ($Target) {
  'clean'   { Clean-Build }
  'logo'    { Copy-Logo }
  'icons'   { Build-Icons }
  'splash'  { Build-Splash }
  'apk'     { Build-Apk }
  'windows' { Build-Windows }
  'all'     { Build-All }
}

Write-Host "`n✓ Build completado exitosamente." -ForegroundColor Green
