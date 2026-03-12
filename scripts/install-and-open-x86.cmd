@echo off
setlocal EnableDelayedExpansion

set "DEVICE=%~1"
if "%DEVICE%"=="" set "DEVICE=emulator-5556"
set "DEV_URL=exp+boyfriendcam://expo-development-client/?url=http%%3A%%2F%%2F127.0.0.1%%3A8081"

call "%~dp0with-android-env.cmd" adb.exe -s %DEVICE% reverse tcp:8081 tcp:8081
if errorlevel 1 exit /b %ERRORLEVEL%

call "%~dp0with-android-env.cmd" adb.exe -s %DEVICE% install -r "%~dp0..\android\app\build\outputs\apk\debug\app-debug.apk"
if errorlevel 1 exit /b %ERRORLEVEL%

"C:\Users\david\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s %DEVICE% shell am start -a android.intent.action.VIEW -d "!DEV_URL!"
exit /b %ERRORLEVEL%
