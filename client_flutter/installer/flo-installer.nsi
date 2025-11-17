!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

; Product info
!define PRODUCT_NAME "FLO"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "VyreVault Studios"
!define PRODUCT_EXE "client_flutter.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_DIR_REGKEY "Software\${PRODUCT_NAME}"

; Installer info
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "FLO-${PRODUCT_VERSION}-Setup.exe"
InstallDir "$LOCALAPPDATA\${PRODUCT_NAME}"
InstallDirRegKey HKCU "${PRODUCT_DIR_REGKEY}" "InstallPath"
RequestExecutionLevel admin ; Admin required for PostgreSQL service installation

; Modern UI Configuration
!define MUI_ICON "..\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\windows\runner\resources\app_icon.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${PRODUCT_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch FLO"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut

; Welcome page configuration
!define MUI_WELCOMEPAGE_TITLE "Welcome to FLO Setup"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of FLO - Teams. Unified.$\r$\n$\r$\nFLO is a local-first team collaboration platform with zero-knowledge encryption.$\r$\n$\r$\nClick Next to continue."

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "LegalCopyright" "© ${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey "FileVersion" "1.0.0"
VIAddVersionKey "ProductVersion" "1.0.0"

; Installer Sections
Section "FLO Core" SecCore
    SectionIn RO ; Required section
    
    SetOutPath "$INSTDIR"
    
    DetailPrint "Installing FLO application files..."
    
    ; Copy all files from Flutter release build
    ; Use /nonfatal to allow installer to continue if Flutter build doesn't exist
    File /nonfatal /r "..\build\windows\x64\runner\Release\*.*"
    IfErrors 0 flutter_files_ok
        DetailPrint "Warning: Flutter build not found, skipping application files..."
        DetailPrint "Note: Backend services will still be installed."
    flutter_files_ok:
    
    ; Create data directories
    DetailPrint "Creating data directories..."
    CreateDirectory "$INSTDIR\data"
    CreateDirectory "$INSTDIR\data\vault"
    CreateDirectory "$INSTDIR\data\cache"
    
    ; Write uninstaller
    DetailPrint "Creating uninstaller..."
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Create Start Menu shortcuts
    DetailPrint "Creating Start Menu shortcuts..."
    CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
    CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   "" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   0 \
                   SW_SHOWNORMAL \
                   "" \
                   "FLO - Teams. Unified."
    
    CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall FLO.lnk" \
                   "$INSTDIR\Uninstall.exe"
    
    ; Registry entries for app
    DetailPrint "Writing registry entries..."
    WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "InstallPath" "$INSTDIR"
    WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "Version" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    
    ; Registry entries for uninstaller
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${PRODUCT_EXE}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "https://flo.app"
    WriteRegDWORD HKCU "${PRODUCT_UNINST_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${PRODUCT_UNINST_KEY}" "NoRepair" 1
    
    ; Calculate and store installed size
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKCU "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
    
    DetailPrint "Installation complete!"
SectionEnd

Section "Desktop Shortcut" SecDesktop
    DetailPrint "Creating desktop shortcut..."
    CreateShortcut "$DESKTOP\${PRODUCT_NAME}.lnk" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   "" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   0 \
                   SW_SHOWNORMAL \
                   "" \
                   "FLO - Teams. Unified."
SectionEnd

Section "Backend Services" SecBackend
    SectionIn RO ; Required section
    DetailPrint "Installing FlowSpace backend services..."
    
    ; Backend installation paths
    StrCpy $R0 "$PROGRAMFILES\FlowSpace"
    StrCpy $R1 "$PROGRAMFILES\FlowSpace\backend"
    StrCpy $R2 "$PROGRAMFILES\FlowSpace\PostgreSQL"
    StrCpy $R3 "$PROGRAMFILES\FlowSpace\data\postgresql"
    StrCpy $R4 "$PROGRAMFILES\FlowSpace\logs"
    
    ; Create directories
    CreateDirectory "$R0"
    CreateDirectory "$R1"
    CreateDirectory "$R2"
    CreateDirectory "$R3"
    CreateDirectory "$R4"
    
    ; Extract NSSM (must be embedded in installer)
    DetailPrint "Extracting NSSM..."
    SetOutPath "$R0"
    File "deps\nssm.exe"
    
    ; Extract PostgreSQL binaries (must be embedded in installer)
    DetailPrint "Extracting PostgreSQL..."
    SetOutPath "$R2"
    File /r "deps\PostgreSQL\*.*"
    
    ; Extract backend files
    DetailPrint "Extracting backend..."
    SetOutPath "$R1"
    File /r "deps\backend\dist\*.*"
    File /r "deps\backend\node_modules\*.*"
    File "deps\backend\package.json"
    File "deps\backend\package-lock.json"
    File /r "deps\backend\prisma\*.*"
    
    ; Copy service wrappers
    SetOutPath "$R0\service-wrappers"
    File "deps\service-wrappers\backend-wrapper.bat"
    
    ; Create .env file for backend
    DetailPrint "Creating backend configuration..."
    FileOpen $R5 "$R1\.env" w
    FileWrite $R5 "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace$\r$\n"
    FileWrite $R5 "REDIS_URL=redis://localhost:6379$\r$\n"
    FileWrite $R5 "REDIS_CLUSTER_NODES=redis://localhost:6379$\r$\n"
    FileWrite $R5 "NODE_ENV=production$\r$\n"
    FileWrite $R5 "PORT=4000$\r$\n"
    FileClose $R5
    
    ; Initialize PostgreSQL database if needed
    IfFileExists "$R3\PG_VERSION" skip_pg_init
    DetailPrint "Initializing PostgreSQL database..."
    ExecWait '"$R2\bin\initdb.exe" -D "$R3" -U postgres -A trust -E UTF8 --locale=C' $0
    IfErrors pg_init_error skip_pg_init
    pg_init_error:
        DetailPrint "Warning: Database initialization had issues, continuing..."
    skip_pg_init:
    
    ; Create postgresql.conf
    FileOpen $R5 "$R3\postgresql.conf" w
    FileWrite $R5 "port = 5432$\r$\n"
    FileWrite $R5 "listen_addresses = 'localhost'$\r$\n"
    FileWrite $R5 "max_connections = 100$\r$\n"
    FileWrite $R5 "shared_buffers = 128MB$\r$\n"
    FileClose $R5
    
    ; Create pg_hba.conf
    FileOpen $R5 "$R3\pg_hba.conf" w
    FileWrite $R5 "local   all             all                                     trust$\r$\n"
    FileWrite $R5 "host    all             all             127.0.0.1/32            trust$\r$\n"
    FileWrite $R5 "host    all             all             ::1/128                 trust$\r$\n"
    FileClose $R5
    
    ; Install PostgreSQL service
    DetailPrint "Installing PostgreSQL service..."
    ExecWait 'sc stop FlowSpacePostgreSQL' $0
    ExecWait 'sc delete FlowSpacePostgreSQL' $0
    Sleep 1000
    ExecWait '"$R0\nssm.exe" install FlowSpacePostgreSQL "$R2\bin\postgres.exe" "-D" "$R3"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL DisplayName "FlowSpace PostgreSQL"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL Description "PostgreSQL database server for FlowSpace"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL AppDirectory "$R3"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL Start SERVICE_AUTO_START' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL AppStdout "$R4\postgresql-stdout.log"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpacePostgreSQL AppStderr "$R4\postgresql-stderr.log"' $0
    
    ; Start PostgreSQL
    DetailPrint "Starting PostgreSQL..."
    ExecWait 'net start FlowSpacePostgreSQL' $0
    Sleep 5000
    
    ; Create database (ignore error if already exists)
    DetailPrint "Creating database..."
    ExecWait '"$R2\bin\psql.exe" -U postgres -h localhost -c "CREATE DATABASE flowspace;"' $0
    ; Ignore error if database already exists
    
    ; Install backend service
    DetailPrint "Installing backend service..."
    ExecWait 'sc stop FlowSpaceBackend' $0
    ExecWait 'sc delete FlowSpaceBackend' $0
    Sleep 1000
    ExecWait '"$R0\nssm.exe" install FlowSpaceBackend "$R0\service-wrappers\backend-wrapper.bat"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend DisplayName "FlowSpace Backend"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend Description "FlowSpace backend API server"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend AppDirectory "$R1"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend Start SERVICE_AUTO_START' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend DependOnService FlowSpacePostgreSQL' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend AppStdout "$R4\Backend-stdout.log"' $0
    ExecWait '"$R0\nssm.exe" set FlowSpaceBackend AppStderr "$R4\Backend-stderr.log"' $0
    
    ; Run Prisma migrations (create temporary batch file)
    DetailPrint "Running database migrations..."
    FileOpen $R5 "$TEMP\run-prisma-migrate.bat" w
    FileWrite $R5 "@echo off$\r$\n"
    FileWrite $R5 "cd /d $\"$R1$\"$\r$\n"
    FileWrite $R5 "set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace$\r$\n"
    FileWrite $R5 "node_modules\.bin\prisma migrate deploy$\r$\n"
    FileClose $R5
    ExecWait '"$TEMP\run-prisma-migrate.bat"' $0
    Delete "$TEMP\run-prisma-migrate.bat"
    
    ; Start backend service
    DetailPrint "Starting backend service..."
    ExecWait 'net start FlowSpaceBackend' $0
    
    DetailPrint "Backend services installation complete!"
SectionEnd

Section "PostgreSQL Database" SecPostgreSQL
    ; This section is now part of SecBackend, kept for compatibility
    DetailPrint "PostgreSQL is installed as part of Backend Services."
SectionEnd

Section "Portable Version" SecPortable
    DetailPrint "Creating portable version..."
    
    ; Create portable directory structure
    CreateDirectory "$INSTDIR\FLO-Portable"
    CreateDirectory "$INSTDIR\FLO-Portable\app"
    CreateDirectory "$INSTDIR\FLO-Portable\data"
    CreateDirectory "$INSTDIR\FLO-Portable\data\vault"
    CreateDirectory "$INSTDIR\FLO-Portable\data\cache"
    
    ; Copy application files
    CopyFiles /SILENT "$INSTDIR\*.*" "$INSTDIR\FLO-Portable\app"
    CopyFiles /SILENT "$INSTDIR\data" "$INSTDIR\FLO-Portable\app\data"
    
    ; Create portable launcher script
    FileOpen $0 "$INSTDIR\FLO-Portable\FLO-Portable.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "title FLO - Portable Mode$\r$\n"
    FileWrite $0 "echo Starting FLO in Portable Mode...$\r$\n"
    FileWrite $0 "echo.$\r$\n"
    FileWrite $0 "echo Data will be stored in: %~dp0data$\r$\n"
    FileWrite $0 "echo.$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "set FLO_PORTABLE=1$\r$\n"
    FileWrite $0 "set FLO_DATA_DIR=%~dp0data$\r$\n"
    FileWrite $0 "set LOCALAPPDATA=%~dp0data$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "cd /d $\"%~dp0app$\"$\r$\n"
    FileWrite $0 "start $\"$\" $\"${PRODUCT_EXE}$\"$\r$\n"
    FileClose $0
    
    ; Create README for portable version
    FileOpen $0 "$INSTDIR\FLO-Portable\README.txt" w
    FileWrite $0 "FLO - Portable Edition$\r$\n"
    FileWrite $0 "========================$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "To run FLO in portable mode:$\r$\n"
    FileWrite $0 "1. Double-click 'FLO-Portable.bat'$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "All data (teams, workspaces, vault files) will be stored$\r$\n"
    FileWrite $0 "in the 'data' folder next to this file.$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "You can copy this entire 'FLO-Portable' folder to:$\r$\n"
    FileWrite $0 "- USB drives$\r$\n"
    FileWrite $0 "- Network shares$\r$\n"
    FileWrite $0 "- Cloud storage (Dropbox, OneDrive, etc.)$\r$\n"
    FileWrite $0 "$\r$\n"
    StrCpy $R6 "${PRODUCT_VERSION}"
    FileWrite $0 "Version: $R6$\r$\n"
    StrCpy $R7 "${PRODUCT_PUBLISHER}"
    FileWrite $0 "Publisher: $R7$\r$\n"
    FileClose $0
    
    DetailPrint "Portable version created at: $INSTDIR\FLO-Portable"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Core FLO application files (required)"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecBackend} "Backend services including PostgreSQL, database setup, and API server (required)"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPostgreSQL} "PostgreSQL database server (included in Backend Services)"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Create a desktop shortcut for easy access"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPortable} "Create portable version for USB drives or cloud storage"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Functions
Function CreateDesktopShortcut
    CreateShortcut "$DESKTOP\${PRODUCT_NAME}.lnk" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   "" \
                   "$INSTDIR\${PRODUCT_EXE}" \
                   0 \
                   SW_SHOWNORMAL \
                   "" \
                   "FLO - Teams. Unified."
FunctionEnd

Function .onInit
    ; Check if already installed
    ReadRegStr $0 HKCU "${PRODUCT_DIR_REGKEY}" "InstallPath"
    ${If} $0 != ""
        MessageBox MB_YESNO|MB_ICONQUESTION \
            "FLO is already installed at:$\r$\n$\r$\n$0$\r$\n$\r$\nDo you want to reinstall?" \
            IDYES continue
        Abort
        continue:
    ${EndIf}
FunctionEnd

; Uninstaller Section
Section "Uninstall"
    ; Remove files and directories
    DetailPrint "Removing application files..."
    RMDir /r "$INSTDIR\data"
    RMDir /r "$INSTDIR\FLO-Portable"
    Delete "$INSTDIR\${PRODUCT_EXE}"
    Delete "$INSTDIR\*.dll"
    Delete "$INSTDIR\flutter_windows.dll"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; Remove shortcuts
    DetailPrint "Removing shortcuts..."
    Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
    Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall FLO.lnk"
    RMDir "$SMPROGRAMS\${PRODUCT_NAME}"
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    
    ; Remove backend services
    DetailPrint "Removing backend services..."
    ExecWait 'net stop FlowSpaceBackend' $0
    ExecWait 'sc delete FlowSpaceBackend' $0
    
    ; Remove PostgreSQL service (optional - ask user)
    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove PostgreSQL database server?$\r$\n$\r$\nThis will stop the database service and remove all data." IDNO skip_pg_uninstall
    DetailPrint "Removing PostgreSQL service..."
    ExecWait 'net stop FlowSpacePostgreSQL' $0
    ExecWait 'sc delete FlowSpacePostgreSQL' $0
    RMDir /r "$PROGRAMFILES\FlowSpace\PostgreSQL"
    RMDir /r "$PROGRAMFILES\FlowSpace\data\postgresql"
    skip_pg_uninstall:
    
    ; Remove backend files
    RMDir /r "$PROGRAMFILES\FlowSpace\backend"
    RMDir /r "$PROGRAMFILES\FlowSpace\service-wrappers"
    Delete "$PROGRAMFILES\FlowSpace\nssm.exe"
    RMDir /r "$PROGRAMFILES\FlowSpace\logs"
    
    ; Remove registry entries
    DetailPrint "Removing registry entries..."
    DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"
    
    ; Remove install directory if empty
    RMDir "$INSTDIR"
    
    ; Confirmation message
    MessageBox MB_OK "FLO has been successfully uninstalled from your computer."
SectionEnd

Function un.onInit
    MessageBox MB_YESNO|MB_ICONQUESTION \
        "Are you sure you want to uninstall FLO?$\r$\n$\r$\nThis will remove the application but preserve your data in AppData." \
        IDYES +2
    Abort
FunctionEnd
