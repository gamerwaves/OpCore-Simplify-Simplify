@echo off
title Hackintosh Builder (Windows)

:: ==============================
:: Setup
:: ==============================
if not exist tools mkdir tools
cd tools

echo ==============================
echo Downloading tools...
echo ==============================

if not exist OpCore-Simplify (
    git clone https://github.com/lzhoang2801/OpCore-Simplify.git
)

if not exist macrecovery.py (
    curl -L -o macrecovery.py https://raw.githubusercontent.com/acidanthera/OpenCorePkg/master/Utilities/macrecovery/macrecovery.py
)

cd OpCore-Simplify

:: ==============================
:: Patch to export macOS version
:: ==============================
echo.
echo Patching opcore...

powershell -Command ^
"$f='opcore-simplify.py'; ^
$c=Get-Content $f -Raw; ^
$p='self.build_opencore_efi'; ^
$r='self.build_opencore_efi`n                open(\"macos.txt\",\"w\").write(macos_version)'; ^
$c=$c -replace $p,$r; ^
Set-Content $f $c"

:: ==============================
:: Run opcore
:: ==============================
echo.
echo Run through opcore normally.
echo Build EFI (option 6).
pause

python opcore-simplify.py

if not exist macos.txt (
    echo Failed to detect macOS version
    pause
    exit /b
)

set /p DARWIN=<macos.txt
for /f "tokens=1 delims=." %%i in ("%DARWIN%") do set MAJOR=%%i

echo Detected Darwin: %DARWIN%

:: ==============================
:: Map to board-id
:: ==============================
set BOARD=Mac-7BA5B2D9E42DDD94

if %MAJOR%==17 set BOARD=Mac-7BA5B2D9E42DDD94
if %MAJOR%==18 set BOARD=Mac-7BA5B2DFE22DDD8C
if %MAJOR%==19 set BOARD=Mac-CFF7D910A743CAAF
if %MAJOR%==20 set BOARD=Mac-2BD1B31983FE1663
if %MAJOR%==21 set BOARD=Mac-E43C1C25D4880AD6
if %MAJOR%==22 set BOARD=Mac-B4831CEBD52A0C4C
if %MAJOR%==23 set BOARD=Mac-827FAC58A8FDFA22
if %MAJOR%==24 set BOARD=Mac-7BA5B2D9E42DDD94
if %MAJOR%==25 set BOARD=Mac-7BA5B2D9E42DDD94
if %MAJOR%==26 set BOARD=Mac-CFF7D910A743CAAF

echo Using board-id: %BOARD%

cd ..

:: ==============================
:: Download macOS
:: ==============================
echo.
echo Downloading macOS recovery...
python macrecovery.py -b %BOARD% -m 00000000000000000 download

:: ==============================
:: Mode selection
:: ==============================
echo.
echo ==============================
echo Select install mode:
echo 1. USB (recommended)
echo 2. GRUB2Win (internal boot)
echo ==============================

set /p MODE=Enter choice:

:: ==============================
:: USB MODE
:: ==============================
if "%MODE%"=="1" (

    echo list disk > "%temp%\list.txt"
    diskpart /s "%temp%\list.txt"

    set /p DISKNUM=Enter USB disk number:

    echo WARNING: THIS WILL ERASE DISK %DISKNUM%
    set /p CONFIRM=Type YES:

    if /i not "%CONFIRM%"=="YES" exit /b

    (
    echo select disk %DISKNUM%
    echo clean
    echo create partition primary
    echo format fs=fat32 quick
    echo assign
    echo exit
    ) > "%temp%\format.txt"

    diskpart /s "%temp%\format.txt"

    set /p USB=Enter USB drive letter (e.g. E:):

    xcopy /E /I /Y OpCore-Simplify\Results\EFI %USB%\EFI

    if exist com.apple.recovery.boot (
        xcopy /E /I /Y com.apple.recovery.boot %USB%\com.apple.recovery.boot
    )

    echo USB READY
)

:: ==============================
:: GRUB2Win MODE
:: ==============================
if "%MODE%"=="2" (

    echo.
    echo Make sure GRUB2Win is installed first!
    pause

    set EFI=C:\EFI\OC

    mkdir C:\EFI
    mkdir %EFI%

    xcopy /E /I /Y OpCore-Simplify\Results\EFI %EFI%

    echo.
    echo Add this entry in GRUB2Win:

    echo.
    echo menuentry "OpenCore" {
    echo     search --file --no-floppy --set=root /EFI/OC/OpenCore.efi
    echo     chainloader /EFI/OC/OpenCore.efi
    echo }

    echo.
    echo Then reboot and select OpenCore from GRUB.
)

:: ==============================
:: Done
:: ==============================
echo.
echo ==============================
echo DONE
echo ==============================

pause
