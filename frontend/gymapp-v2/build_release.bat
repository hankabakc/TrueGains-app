@echo off
echo ============================================================
echo GYMAPP-V2 RELEASE BUILD SCRIPT (OBFUSCATED)
echo ============================================================

echo [1/2] Android APK Derleniyor (Obfuscated)...
call flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo.
echo [2/2] iOS IPA Hazirlaniyor (Obfuscated)...
echo Not: iOS derlemesi icin Mac ve Xcode gereklidir.
echo Komut: flutter build ipa --release --obfuscate --split-debug-info=build/ios/outputs/symbols

echo.
echo ============================================================
echo ISLEM TAMAMLANDI.
echo ============================================================
pause
