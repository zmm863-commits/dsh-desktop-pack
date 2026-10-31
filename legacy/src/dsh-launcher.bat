@echo off
setlocal EnableExtensions
title 泡泡猫 DSH
set "LAUNCHDIR=%~dp0"
for %%I in ("%LAUNCHDIR%..") do set "ROOT=%%~fI"
set "DSH_DATA=%APPDATA%\PaopaocatDSH"
if not exist "%DSH_DATA%" mkdir "%DSH_DATA%" >nul 2>&1

if not exist "%DSH_DATA%\profiles\web\node_modules" (
  echo 【1/3】正在初始化数据目录（仅首次）...
  robocopy "%ROOT%\data-template" "%DSH_DATA%" /E /NFL /NDL /NJH /NJS /NP >nul
)

if not exist "%DSH_DATA%\.env" (
  echo 【2/3】首次启动：请填入你的 DeepSeek API Key...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\launcher\first-run.ps1" -EnvFile "%DSH_DATA%\.env"
  if errorlevel 1 (
    echo.
    echo 未输入密钥，已退出。可重新双击桌面图标，或到 https://platform.deepseek.com 申请密钥。
    pause
    exit /b 1
  )
)

findstr /c:"__INSTALLDIR__" "%DSH_DATA%\settings.yaml" >nul 2>&1
if not errorlevel 1 powershell -NoProfile -Command "(Get-Content -LiteralPath '%DSH_DATA%\settings.yaml' -Raw) -replace '__INSTALLDIR__','%ROOT:\=/%' | Set-Content -LiteralPath '%DSH_DATA%\settings.yaml' -Encoding UTF8"

rem 内置 Git（bash 工具即开即用）与 Edge 无头浏览器（IM 插件免装 Chrome）
set "PATH=%ROOT%\git\cmd;%ROOT%\git\mingw64\bin;%ROOT%\node;%PATH%"
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "PUPPETEER_EXECUTABLE_PATH=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not defined PUPPETEER_EXECUTABLE_PATH if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "PUPPETEER_EXECUTABLE_PATH=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

netstat -ano | findstr ":3080" | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
  echo 检测到泡泡猫 DSH 已在运行，正在打开浏览器...
  start "" "http://127.0.0.1:3080"
  timeout /t 3 >nobreak >nul
  exit /b 0
)

echo 【3/3】正在启动泡泡猫 DSH，浏览器将自动打开 http://127.0.0.1:3080
echo 关闭本窗口即可停止 DSH。
echo.
set "DSH_HOME=%DSH_DATA%"
"%ROOT%\node\node.exe" "%ROOT%\app\lib\bin.js" web
echo.
echo 泡泡猫 DSH 已退出。
pause
