@echo off
echo Set editorMode to true in lib/constants.dart
pause
start /wait cmd /c "flutter build windows && exit"
iscc "editor builder script.iss"
echo Set editorMode to false in lib/constants.dart
pause
start /wait cmd /c "flutter build appbundle && exit"
rm -r distribution
mkdir distribution
xcopy "build\app\outputs\bundle\release\app-release.aab" "distribution"
xcopy "ShamScoutEditor.exe" "distribution"
pause