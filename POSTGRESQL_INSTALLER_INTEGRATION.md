# PostgreSQL Integration with NSIS Installer

## Summary

PostgreSQL has been integrated into the FLO NSIS installer so it installs and starts automatically with the program.

## Changes Made

### 1. NSIS Installer (`flo-installer.nsi`)
- **Changed execution level** from `user` to `admin` (required for service installation)
- **Added Components page** to allow users to select PostgreSQL installation
- **Added PostgreSQL section** (`SecPostgreSQL`) that:
  - Extracts PostgreSQL binaries from installer
  - Initializes database if needed
  - Creates configuration files (postgresql.conf, pg_hba.conf)
  - Installs PostgreSQL as Windows Service using NSSM
  - Starts the service automatically
  - Creates the `flowspace` database
- **Updated uninstaller** to optionally remove PostgreSQL service

### 2. Bundle Installer (`bundle-installer.ps1`)
- **Added PostgreSQL download/copy** section
- Attempts to copy from local installation
- Falls back to downloading portable PostgreSQL if not found
- **Added NSSM** to binaries list (required for service installation)
- Updated README to include PostgreSQL

### 3. Installation Process

When building the installer:
1. Run `bundle-installer.ps1` to package all binaries including PostgreSQL
2. PostgreSQL binaries should be in `Binaries\PostgreSQL\` folder
3. NSSM should be in `Binaries\` folder
4. Build NSIS installer - it will embed PostgreSQL and NSSM

When installing:
1. User runs `FLO-1.0.0-Setup.exe`
2. Installer prompts for admin privileges
3. User can select "PostgreSQL Database" component
4. Installer extracts PostgreSQL to `C:\Program Files\FlowSpace\PostgreSQL`
5. Initializes database in `C:\Program Files\FlowSpace\data\postgresql`
6. Installs as Windows Service "FlowSpacePostgreSQL"
7. Service starts automatically and is set to auto-start with Windows
8. Creates `flowspace` database

## File Structure

```
FLO-Installer/
├── Binaries/
│   ├── PostgreSQL/          # PostgreSQL portable binaries
│   │   └── bin/
│   │       ├── postgres.exe
│   │       ├── psql.exe
│   │       └── initdb.exe
│   └── nssm.exe              # Service manager
└── FLO-1.0.0-Setup.exe       # NSIS installer
```

## Service Configuration

- **Service Name**: `FlowSpacePostgreSQL`
- **Display Name**: "FlowSpace PostgreSQL"
- **Start Type**: Automatic (starts with Windows)
- **Port**: 5432
- **Database**: `flowspace`
- **User**: `postgres` (no password, trust authentication for localhost)

## Next Steps

1. **Build the installer**:
   ```powershell
   cd C:\FlowSpace
   .\bundle-installer.ps1
   cd client_flutter\installer
   .\build-installer.ps1
   ```

2. **Test installation**:
   - Run installer on clean machine
   - Verify PostgreSQL service starts
   - Verify database is created
   - Verify backend can connect

3. **Update installer to embed files**:
   - The NSIS script currently looks for files in `$EXEDIR\PostgreSQL`
   - For a single-file installer, you need to:
     - Use `File` command to embed PostgreSQL files
     - Extract them during installation
     - Or use a separate installer package

## Notes

- PostgreSQL binaries are large (~100MB+), consider:
  - Making it optional component
  - Downloading during installation
  - Using a separate installer package
- The installer currently requires admin privileges
- Database data persists in `C:\Program Files\FlowSpace\data\postgresql`
- Uninstaller asks user if they want to remove PostgreSQL

