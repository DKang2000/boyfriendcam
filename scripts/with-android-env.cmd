@echo off
setlocal

set "JAVA_HOME=C:\Users\david\AppData\Local\Programs\Java\jdk-17.0.18+8"
set "ANDROID_HOME=C:\Users\david\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\emulator;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%"

call %*
