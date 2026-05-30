@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Volchay Wallpapers - Build Script
echo ========================================
echo.

REM Пути к инструментам
set "QT_DIR=D:\Aps\Qt\6.11.1\msvc2022_64"
set "VS_DIR=C:\Program Files\Microsoft Visual Studio\18\Community"
set "VCVARS=%VS_DIR%\VC\Auxiliary\Build\vcvars64.bat"

REM Проверка Qt
if not exist "%QT_DIR%\bin\qmake.exe" (
    echo [ERROR] Qt not found at: %QT_DIR%
    exit /b 1
)

REM Проверка MSVC
if not exist "%VCVARS%" (
    echo [ERROR] MSVC not found at: %VS_DIR%
    exit /b 1
)

echo [1/5] Setting up MSVC environment...
call "%VCVARS%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to setup MSVC environment
    exit /b 1
)

echo [2/5] Configuring CMake...
set "PATH=%QT_DIR%\bin;%PATH%"
set "CMAKE_PREFIX_PATH=%QT_DIR%"

REM Создаём build директорию
if not exist build mkdir build
cd build

REM Конфигурация CMake (используем NMake вместо VS solution)
cmake -G "NMake Makefiles" ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
      -DMPV_ROOT="%~dp0mpv-sdk" ^
      ..

if errorlevel 1 (
    echo [ERROR] CMake configuration failed
    cd ..
    exit /b 1
)

echo [3/5] Building project...
nmake

if errorlevel 1 (
    echo [ERROR] Build failed
    cd ..
    exit /b 1
)

echo [4/5] Deploying Qt dependencies...
"%QT_DIR%\bin\windeployqt.exe" --qmldir ..\src\qml --no-translations VolchayWallpapers.exe

if errorlevel 1 (
    echo [ERROR] windeployqt failed
    cd ..\..
    exit /b 1
)

echo [5/5] Checking for libmpv...
if exist "D:\Aps\Git\Wallpapers\libmpv-2.dll" (
    copy /Y "D:\Aps\Git\Wallpapers\libmpv-2.dll" .
    echo libmpv-2.dll copied from existing installation
) else if exist "..\mpv-sdk\libmpv-2.dll" (
    copy /Y "..\mpv-sdk\libmpv-2.dll" .
    echo libmpv-2.dll copied from mpv-sdk
) else (
    echo [WARNING] libmpv-2.dll not found, app will run in stub mode
    echo [INFO] You can copy libmpv-2.dll manually to build\
)

cd ..

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo Output: build\VolchayWallpapers.exe
echo.

exit /b 0
