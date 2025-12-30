@echo off
setlocal EnableDelayedExpansion

echo ========================================================
echo  SPA-CY BUILDER FOR WINDOWS ARM64
echo  (Dynamic Environment Detection)
echo ========================================================

:: --- STEP 1: DETECT PYTHON ---
echo.
echo Detecting Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo FAIL: Python is not in your PATH. Please install Python 3.11+ (ARM64) and add it to PATH.
    pause
    exit /b 1
)

:: Get the actual path of the running Python
for /f "delims=" %%i in ('python -c "import sys; print(sys.prefix)"') do set "PYTHON_DIR=%%i"
echo [SUCCESS] Targeted Python: "%PYTHON_DIR%"

:: --- STEP 2: DETECT VISUAL STUDIO BUILD TOOLS ---
echo.
echo Detecting Visual Studio Build Tools...
:: Check standard 2022 path
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS_ROOT=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
) else (
    :: Check "18" path (Preview/Enterprise/Alternate versions)
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS_ROOT=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools"
    ) else (
        echo FAIL: Could not find Visual Studio 2022 Build Tools.
        echo Please ensure VS2022 Build Tools are installed in the default location.
        pause
        exit /b 1
    )
)
echo [SUCCESS] Found Build Tools at: "%VS_ROOT%"

:: --- STEP 3: ACTIVATE ENVIRONMENT ---
echo.
echo Activating Visual Studio ARM64 Environment...
call "%VS_ROOT%\VC\Auxiliary\Build\vcvarsall.bat" arm64 >nul
if %errorlevel% neq 0 (
    echo FAIL: Could not run vcvarsall.bat
    pause
    exit /b 1
)

:: --- STEP 4: PREPARE SHIMS (Clang & LLD) ---
if not exist "C:\cls_shim" mkdir "C:\cls_shim"
echo Creating Compiler Shims...

:: Check if Clang components exist before copying
if not exist "%VS_ROOT%\VC\Tools\Llvm\ARM64\bin\clang-cl.exe" (
    echo FAIL: Clang for Windows (ARM64) is not installed in Visual Studio.
    pause
    exit /b 1
)

copy /Y "%VS_ROOT%\VC\Tools\Llvm\ARM64\bin\clang-cl.exe" "C:\cls_shim\cl.exe" >nul
copy /Y "%VS_ROOT%\VC\Tools\Llvm\ARM64\bin\lld-link.exe" "C:\cls_shim\link.exe" >nul

:: --- STEP 5: HUNT FOR LIBRARIES (Auto-Detection) ---
echo.
echo Hunting for msvcrt.lib...
set "MSVC_LIB_PATH="
for /f "delims=" %%F in ('dir /b /s "%VS_ROOT%\VC\Tools\MSVC\*msvcrt.lib"') do (
    echo %%F | findstr /i "arm64" >nul
    if !errorlevel! equ 0 ( set "MSVC_LIB_PATH=%%~dpF" & goto :FOUND_MSVC )
)
:FOUND_MSVC
if "!MSVC_LIB_PATH!"=="" ( echo FAIL: MSVC Libs not found. Check VS Installer. & pause & exit /b 1 )

echo Hunting for kernel32.lib...
set "KIT_LIB_PATH="
for /f "delims=" %%F in ('dir /b /s "C:\Program Files (x86)\Windows Kits\10\Lib\*kernel32.lib"') do (
    echo %%F | findstr /i "arm64" >nul
    if !errorlevel! equ 0 ( set "KIT_LIB_PATH=%%~dpF" & goto :FOUND_KIT )
)
:FOUND_KIT
if "!KIT_LIB_PATH!"=="" ( echo FAIL: Windows SDK Libs not found. Check VS Installer. & pause & exit /b 1 )

echo Hunting for ucrt.lib...
set "UCRT_LIB_PATH="
for /f "delims=" %%F in ('dir /b /s "C:\Program Files (x86)\Windows Kits\10\Lib\*ucrt.lib"') do (
    echo %%F | findstr /i "arm64" >nul
    if !errorlevel! equ 0 ( set "UCRT_LIB_PATH=%%~dpF" & goto :FOUND_UCRT )
)
:FOUND_UCRT

:: --- STEP 6: FORCE ENVIRONMENT VARIABLES ---
set "LIB=!MSVC_LIB_PATH!;!KIT_LIB_PATH!;!UCRT_LIB_PATH!;%LIB%"
set "PATH=C:\cls_shim;%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%"
set DISTUTILS_USE_SDK=1
set MSSdk=1

:: The Critical Fixes for Clang strictness
set "CL=/clang:-Wno-c++11-narrowing /clang:-Wno-deprecated-declarations /clang:-Wno-unused-function"

:: --- STEP 7: RUN BUILD ---
echo.
echo -------------------------------------
echo STARTING INSTALL
echo -------------------------------------

"%PYTHON_DIR%\python.exe" -m pip install -r requirements.txt --no-build-isolation --user
if %errorlevel% neq 0 (
    echo Requirements install failed.
    pause
    exit /b %errorlevel%
)

echo.
echo BUILDING WHEEL...
"%PYTHON_DIR%\python.exe" -m pip wheel . -w dist/ --no-build-isolation

echo.
echo ========================================================
echo  DONE! Check the 'dist' folder.
echo ========================================================
pause
