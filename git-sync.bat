@echo off
REM git-sync.bat — Git pull + archive for closed-network transfer
REM
REM Usage:
REM   git-sync.bat                          Pull + archive
REM   git-sync.bat scp user@host:/path      Pull + archive + SCP
REM   git-sync.bat ftp                      Pull + archive + open Explorer
REM
REM Run from any git repository root.
REM Archive saved to .\dist\ (relative to repo root)

setlocal enabledelayedexpansion

REM ── Detect repo ────────────────────────────────────────────────────────
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%i"
if "%REPO_ROOT%"=="" (
    echo [ERROR] Not a git repository.
    exit /b 1
)

for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%i"
for /f "tokens=*" %%i in ('git rev-parse --short HEAD 2^>nul') do set "COMMIT=%%i"
for %%i in ("%REPO_ROOT%") do set "REPO_NAME=%%~nxi"

for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value') do set "DT=%%i"
set "TS=%DT:~0,8%-%DT:~8,4%"

set "DIST_DIR=%REPO_ROOT%\dist"
set "ARCHIVE_NAME=%REPO_NAME%-%BRANCH%-%COMMIT%-%TS%.tar.gz"
set "ARCHIVE_PATH=%DIST_DIR%\%ARCHIVE_NAME%"
set "EXCLUDE_FILE=%~dp0sync-exclude.txt"

echo.
echo  ========================================
echo   git-sync
echo  ========================================
echo   Repo   : %REPO_NAME%
echo   Branch : %BRANCH%  (%COMMIT%)
echo   Output : %ARCHIVE_NAME%
echo  ========================================
echo.

REM ── Pull ───────────────────────────────────────────────────────────────
echo [1/3] Pulling latest...
cd /d "%REPO_ROOT%"
git pull 2>nul
echo.

REM ── Archive ────────────────────────────────────────────────────────────
echo [2/3] Creating archive...
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

if exist "%EXCLUDE_FILE%" (
    tar czf "%ARCHIVE_PATH%" --exclude-from="%EXCLUDE_FILE%" -C "%REPO_ROOT%\.." "%REPO_NAME%"
) else (
    tar czf "%ARCHIVE_PATH%" --exclude=.git --exclude=build --exclude=bin --exclude=lib --exclude=dist --exclude=out --exclude=*.o --exclude=*.a --exclude=*.so --exclude=*.exe --exclude=*.dll --exclude=*.obj --exclude=*.pdb --exclude=node_modules --exclude=__pycache__ -C "%REPO_ROOT%\.." "%REPO_NAME%"
)

if errorlevel 1 (
    echo [ERROR] Archive failed.
    exit /b 1
)

for %%A in ("%ARCHIVE_PATH%") do set "SIZE=%%~zA"
set /a "SIZE_KB=%SIZE% / 1024"
echo   %ARCHIVE_NAME% (%SIZE_KB% KB)
echo.

REM ── Transfer ───────────────────────────────────────────────────────────
set "MODE=%~1"

if "%MODE%"=="scp" (
    set "DEST=%~2"
    if "!DEST!"=="" (
        echo [ERROR] Usage: git-sync.bat scp user@host:/path
        exit /b 1
    )
    echo [3/3] SCP transfer...
    scp "%ARCHIVE_PATH%" "!DEST!/%ARCHIVE_NAME%"
    if errorlevel 1 (
        echo [ERROR] SCP failed.
        exit /b 1
    )
    echo   Sent to !DEST!
    goto :done
)

if "%MODE%"=="ftp" (
    echo [3/3] Opening folder...
    explorer "%DIST_DIR%"
    goto :done
)

echo [3/3] Ready: %ARCHIVE_PATH%
echo.
echo   Transfer:  scp "%ARCHIVE_PATH%" user@server:/path/
echo   Or use Xftp (binary mode)

:done
echo.
echo   Server:  bash git-recv.sh %ARCHIVE_NAME%
echo.
