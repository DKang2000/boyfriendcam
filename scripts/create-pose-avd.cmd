@echo off
setlocal

call "%~dp0with-android-env.cmd" avdmanager.bat create avd -n BoyfriendCam_API_30_x86 -k "system-images;android-30;google_apis;x86" -d pixel_5 -f
