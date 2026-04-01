# git-sync

Git pull + archive + transfer tool for closed-network deployments.

Automates the workflow: **Windows PC (internet) → archive → transfer → closed-network server**.

## Problem

When your deployment servers are on a closed network with no internet access, you need to:
1. `git pull` on your internet-connected PC
2. Create a tar.gz archive
3. Transfer via FTP/SCP
4. Extract on the server
5. Build

This tool automates steps 1-2 and 4-5.

## Quick Start

### Windows (sender)

```cmd
:: Single repo
cd D:\github\myproject
git-sync.bat

:: Multiple repos at once
git-sync-all.bat

:: With SCP auto-transfer
git-sync.bat scp user@server:/incoming
```

### Server (receiver)

```bash
# Extract archive
git-recv.sh myproject-main-abc1234.tar.gz

# Extract to specific path
git-recv.sh myproject-main-abc1234.tar.gz /opt/src/

# Watch a directory for new archives (auto-extract)
git-recv.sh --watch /incoming/
```

## Files

| File | Platform | Description |
|------|----------|-------------|
| `git-sync.bat` | Windows | Pull + archive single repo |
| `git-sync-all.bat` | Windows | Pull + archive multiple repos |
| `git-recv.sh` | Linux | Extract + optional auto-build |
| `sync-exclude.txt` | Both | Default exclude patterns for archive |

## Archive Naming

```
{repo-name}-{branch}-{commit}-{timestamp}.tar.gz
cortex-main-abc1234-20260401-1530.tar.gz
```

## Configuration

### git-sync-all.bat

Edit the `REPOS` variable at the top:
```bat
set "REPOS=D:\github\cortex;D:\github\pinesky-lib;D:\github\other-project"
set "DIST=D:\github\dist"
```

### sync-exclude.txt

Default excludes (auto-created on first run):
```
.git
build
bin
lib
dist
out
node_modules
__pycache__
*.o
*.a
*.so
*.exe
*.dll
*.obj
*.pdb
```

Edit to add project-specific patterns.

## License

MIT
