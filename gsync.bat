@echo off
REM git-sync.bat — Git pull + archive + auto SCP to server
REM
REM Usage:
REM   git-sync.bat              Pull + archive + SCP (uses DEFAULT_DEST)
REM   git-sync.bat --local      Pull + archive only (no transfer)
REM   git-sync.bat ftp          Pull + archive + open Explorer
REM
REM Run from any git repository root.

setlocal enabledelayedexpansion

REM ── Load config ────────────────────────────────────────────────────────
if exist "%~dp0sync.cfg.bat" call "%~dp0sync.cfg.bat"
if "%DEFAULT_DEST%"=="" set "DEFAULT_DEST=user@server:/incoming"

REM ── Resolve SCP executable ─────────────────────────────────────────────
set "SCP_EXE=%WINDIR%\Sysnative\OpenSSH\scp.exe"
if not exist "%SCP_EXE%" set "SCP_EXE=%WINDIR%\System32\OpenSSH\scp.exe"
if not exist "%SCP_EXE%" set "SCP_EXE=scp"

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
echo   Dest   : %DEFAULT_DEST%
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

set "BASE_EXCLUDE=--exclude=.git --exclude=build --exclude=bin --exclude=lib --exclude=out --exclude=*.o --exclude=*.a --exclude=*.so --exclude=*.exe --exclude=*.dll --exclude=*.obj --exclude=*.pdb --exclude=node_modules --exclude=__pycache__"

if exist "%EXCLUDE_FILE%" (
    tar czf "%ARCHIVE_PATH%" %BASE_EXCLUDE% --exclude="%REPO_NAME%/dist" --exclude-from="%EXCLUDE_FILE%" -C "%REPO_ROOT%\.." "%REPO_NAME%"
) else (
    tar czf "%ARCHIVE_PATH%" %BASE_EXCLUDE% --exclude="%REPO_NAME%/dist" -C "%REPO_ROOT%\.." "%REPO_NAME%"
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

if "%MODE%"=="--local" (
    echo [3/3] Archive ready: %ARCHIVE_PATH%
    goto :done
)

if "%MODE%"=="ftp" (
    echo [3/3] Opening folder...
    explorer "%DIST_DIR%"
    goto :done
)

REM Default: SCP transfer
set "DEST=%DEFAULT_DEST%"
if not "%MODE%"=="" if not "%MODE%"=="--local" if not "%MODE%"=="ftp" (
    set "DEST=%MODE%"
)

echo [3/3] Transferring via SCP...
echo   scp %ARCHIVE_NAME% -^> %DEST%
"%SCP_EXE%" "%ARCHIVE_PATH%" "%DEST%/%ARCHIVE_NAME%"
if errorlevel 1 (
    echo.
    echo [WARN] SCP failed. Archive saved locally: %ARCHIVE_PATH%
    echo   Transfer manually via Xftp (binary mode)
) else (
    echo   Transferred OK
)

:done
echo.
echo   Server: bash git-recv.sh %ARCHIVE_NAME%
echo.
