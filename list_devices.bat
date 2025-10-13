@echo off
REM Set PATH to only include essential directories, avoiding pwsh.exe
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin
flutter devices
