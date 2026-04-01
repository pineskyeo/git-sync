@echo off
REM git-sync-all.bat — Pull + archive + SCP multiple repos at once
REM
REM Edit REPOS, DIST, DEFAULT_DEST below, then run.

setlocal enabledelayedexpansion

REM ═══════════════════════════════════════════════════════════════════════
REM  EDIT HERE
REM ═══════════════════════════════════════════════════════════════════════
set "REPOS=D:\github\pineskyeo\cortex;D:\github\pineskyeo\pinesky-lib"
set "DIST=D:\github\dist"
set "DEFAULT_DEST=dc@eupt03:/home/dc/incoming"
REM ═══════════════════════════════════════════════════════════════════════

if not exist "%DIST%" mkdir "%DIST%"

echo.
echo  ========================================
echo   git-sync-all
echo  ========================================
echo   Dest : %DEFAULT_DEST%
echo  ========================================
echo.

set "COUNT=0"
set "FILES="
for %%R in (%REPOS%) do (
    if exist "%%R\.git" (
        cd /d "%%R"
        for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BR=%%b"
        for /f "tokens=*" %%c in ('git rev-parse --short HEAD 2^>nul') do set "CM=%%c"
        for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value') do set "DT=%%i"
        set "TS=!DT:~0,8!-!DT:~8,4!"
        set "NAME=%%~nxR-!BR!-!CM!-!TS!.tar.gz"

        echo  [%%~nxR] pulling...
        git pull 2>nul
        echo  [%%~nxR] archiving...
        tar czf "%DIST%\!NAME!" --exclude=.git --exclude=build --exclude=bin --exclude=lib --exclude=dist --exclude=out --exclude=*.o --exclude=*.a --exclude=*.so --exclude=*.exe --exclude=*.dll -C "%%R\.." "%%~nxR"
        echo   %DIST%\!NAME!
        set "FILES=!FILES! %DIST%\!NAME!"
        set /a "COUNT+=1"
        echo.
    ) else (
        echo  [SKIP] %%R
        echo.
    )
)

echo  ========================================
echo   !COUNT! archive(s) created
echo  ========================================
echo.

REM ── Transfer all ───────────────────────────────────────────────────────
set "MODE=%~1"
if "%MODE%"=="--local" goto :show

echo  Transferring to %DEFAULT_DEST% ...
echo.
for %%F in (%FILES%) do (
    echo   scp %%~nxF ...
    scp "%%F" "%DEFAULT_DEST%/%%~nxF"
    if errorlevel 1 (
        echo   [WARN] Failed: %%~nxF
    ) else (
        echo   OK
    )
)

:show
echo.
echo  Done. Server: bash git-recv.sh *.tar.gz
echo.
