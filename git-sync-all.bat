@echo off
REM git-sync-all.bat — Pull + archive multiple repos at once
REM
REM Edit REPOS and DIST below, then run.
REM All archives saved to DIST folder.

setlocal enabledelayedexpansion

REM ═══════════════════════════════════════════════════════════════════════
REM  EDIT HERE: your repo paths (semicolon separated)
REM ═══════════════════════════════════════════════════════════════════════
set "REPOS=D:\github\pineskyeo\cortex;D:\github\pineskyeo\pinesky-lib"
set "DIST=D:\github\dist"
REM ═══════════════════════════════════════════════════════════════════════

if not exist "%DIST%" mkdir "%DIST%"

echo.
echo  ========================================
echo   git-sync-all
echo  ========================================
echo.

set "COUNT=0"
for %%R in (%REPOS%) do (
    if exist "%%R\.git" (
        cd /d "%%R"
        for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BR=%%b"
        for /f "tokens=*" %%c in ('git rev-parse --short HEAD 2^>nul') do set "CM=%%c"
        for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value') do set "DT=%%i"
        set "TS=!DT:~0,8!-!DT:~8,4!"
        set "NAME=%%~nxR-!BR!-!CM!-!TS!.tar.gz"

        echo  [%%~nxR]
        git pull 2>nul
        tar czf "%DIST%\!NAME!" --exclude=.git --exclude=build --exclude=bin --exclude=lib --exclude=dist --exclude=out --exclude=*.o --exclude=*.a --exclude=*.so --exclude=*.exe --exclude=*.dll -C "%%R\.." "%%~nxR"
        echo   %DIST%\!NAME!
        set /a "COUNT+=1"
        echo.
    ) else (
        echo  [SKIP] %%R — not a git repo
        echo.
    )
)

echo  ========================================
echo   !COUNT! archive(s) in %DIST%
echo  ========================================
echo.
explorer "%DIST%"
