╔═══════════════════════════════════════════════════════════════════════╗
║                    FLŌ - Portable Edition                             ║
║                    Version 1.0.0                                      ║
║                    © VyreVault Studios                                ║
╚═══════════════════════════════════════════════════════════════════════╝

WHAT IS FLŌ PORTABLE?
═════════════════════════════════════════════════════════════════════════
FLŌ Portable is a fully self-contained version of FLŌ that runs entirely
from this folder. No installation required!

All your data (teams, workspaces, chat history, vault files) is stored
locally in the 'data' folder, making it perfect for:

  • USB drives
  • Network shares
  • Cloud storage (Dropbox, OneDrive, Google Drive)
  • Encrypted containers (VeraCrypt, BitLocker)


HOW TO RUN
═════════════════════════════════════════════════════════════════════════
1. Double-click 'FLO-Portable.bat'
2. FLŌ will launch using this folder for all data
3. Close the batch window after FLŌ starts (optional)


FOLDER STRUCTURE
═════════════════════════════════════════════════════════════════════════
  FLO-Portable/
  ├── FLO-Portable.bat    ← Launch this!
  ├── README.txt          ← You are here
  ├── app/                ← Application files (don't modify)
  │   └── client_flutter.exe
  └── data/               ← Your data (portable)
      ├── vault/          ← Encrypted file storage
      └── cache/          ← Temporary files


DATA PORTABILITY
═════════════════════════════════════════════════════════════════════════
• Your database: data/com.example/client_flutter/flowspace.db
• Vault files:   data/vault/
• Cache:         data/cache/

To backup your data:
  → Simply copy the entire 'FLO-Portable' folder


MOVING TO A NEW DEVICE
═════════════════════════════════════════════════════════════════════════
1. Close FLŌ if running
2. Copy the entire 'FLO-Portable' folder to new device
3. Run FLO-Portable.bat on the new device
4. All your data will be instantly available!


SECURITY NOTES
═════════════════════════════════════════════════════════════════════════
✅ Zero-knowledge encryption for messages and vault files
✅ Master encryption key stored securely in Windows Credential Manager
✅ All data is local-first (no cloud dependency)

⚠️  IMPORTANT: If you move this to a new device, you'll need to:
   - Re-enter your password (encryption keys are device-specific)
   - The app will re-encrypt your data with a new device key


SYSTEM REQUIREMENTS
═════════════════════════════════════════════════════════════════════════
• Operating System: Windows 10 or later (64-bit)
• Memory: 4 GB RAM minimum (8 GB recommended)
• Storage: 500 MB available space
• Network: Internet connection for video calls (Jitsi)


FEATURES
═════════════════════════════════════════════════════════════════════════
✓ Teams & Workspaces (5 types: Project/Whiteboard/Document/Brainstorm/Design)
✓ Real-time Chat with channels
✓ File Vault with encryption
✓ Video Calling (Jitsi integration)
✓ Project Management (Kanban boards)
✓ Whiteboard collaboration
✓ Document editor
✓ 100% local-first operation


TROUBLESHOOTING
═════════════════════════════════════════════════════════════════════════
Problem: FLŌ won't start
Solution: Make sure you're running FLO-Portable.bat, not client_flutter.exe

Problem: Data not persisting
Solution: Ensure the 'data' folder has write permissions

Problem: "Database is locked" error
Solution: Only run one instance of FLŌ Portable at a time

Problem: Video calls not working
Solution: Check firewall settings and internet connection


SUPPORT
═════════════════════════════════════════════════════════════════════════
Website:  https://flo.app
Email:    support@flo.app
GitHub:   github.com/vyrevault/flo


LICENSE
═════════════════════════════════════════════════════════════════════════
FLŌ is distributed under the MIT License.
See LICENSE file in the app folder for details.


═════════════════════════════════════════════════════════════════════════
                        Enjoy FLŌ Portable!
                        Teams. Unified. Anywhere.
═════════════════════════════════════════════════════════════════════════
