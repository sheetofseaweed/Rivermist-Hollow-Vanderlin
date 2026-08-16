@echo off
rem Publishes the compiled .rsc to the local web root so EXTERNAL_RSC_URLS can serve it.

rem Must match the rsc root in your Caddyfile.
set "RSC_WEBROOT=C:\srv\vanderlin-cache\rsc"

rem TGS4+ passes the deployment game directory as the first argument.
set "GAMEDIR=%~1"
if "%GAMEDIR%"=="" (echo PostCompile: no game directory argument, skipping rsc publish& exit /b 0)
if not exist "%GAMEDIR%\vanderlin.rsc" (echo PostCompile: no vanderlin.rsc in "%GAMEDIR%", skipping& exit /b 0)

if not exist "%RSC_WEBROOT%" mkdir "%RSC_WEBROOT%"

rem Build under a temp name so clients never fetch a half-written archive.
if exist "%RSC_WEBROOT%\vanderlin.zip.tmp" del /f /q "%RSC_WEBROOT%\vanderlin.zip.tmp"

tar.exe -a -c -f "%RSC_WEBROOT%\vanderlin.zip.tmp" -C "%GAMEDIR%" vanderlin.rsc
if errorlevel 1 (echo PostCompile: tar failed to pack vanderlin.rsc& exit /b 1)

move /y "%RSC_WEBROOT%\vanderlin.zip.tmp" "%RSC_WEBROOT%\vanderlin.zip"
if errorlevel 1 (echo PostCompile: could not swap in the new vanderlin.zip& exit /b 1)

echo PostCompile: published %RSC_WEBROOT%\vanderlin.zip
exit /b 0
