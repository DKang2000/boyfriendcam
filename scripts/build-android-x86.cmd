@echo off
setlocal

pushd "%~dp0..\android"
call "%~dp0with-android-env.cmd" gradlew.bat :app:assembleDebug -PreactNativeArchitectures=x86
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
