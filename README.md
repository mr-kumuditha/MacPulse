# MacPulse - macOS System Optimizer

A production-grade macOS system optimization suite built with Swift and SwiftUI.

## Features

### Free Tier
- **Smart Clean** - Scan and remove cache files, temp files, logs, trash, and more
- **Basic Monitoring** - Disk usage overview

### Pro Tier
- **Duplicate Finder** - SHA256-based duplicate detection with batch operations
- **Storage Analyzer** - Visual disk breakdown and large file finder
- **Real-time Monitor** - Live CPU, RAM, disk, and process monitoring
- **Startup Manager** - Manage LaunchAgents, LaunchDaemons, and login items
- **App Uninstaller** - Complete removal including preferences, caches, and containers
- **Privacy Cleaner** - Browser history, cookies, cache, and session cleanup (Safari, Chrome, Firefox, Brave)
- **Automation Engine** - Scheduled cleaning with customizable frequencies

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

```
MacPulse/
├── App/                    # App entry point, delegate, state
├── Models/                 # Data models and enums
├── ViewModels/             # MVVM view models
├── Views/                  # SwiftUI views
│   ├── Dashboard/
│   ├── Scanner/
│   ├── Duplicates/
│   ├── Storage/
│   ├── Monitor/
│   ├── Startup/
│   ├── Uninstaller/
│   ├── Privacy/
│   ├── Settings/
│   ├── MenuBar/
│   └── Premium/
├── Services/               # Backend services
│   ├── ScanEngine          # File scanning engine
│   ├── DuplicateFinderService
│   ├── LargeFileAnalyzer
│   ├── SystemMonitor       # CPU, RAM, disk monitoring
│   ├── StartupManagerService
│   ├── AppUninstallerService
│   ├── PrivacyCleanerService
│   ├── AutomationEngine
│   ├── SafetyManager       # File protection system
│   ├── FileOperationService
│   └── LicenseManager      # StoreKit 2 integration
├── Utilities/
│   └── Logger
└── Resources/
```

### Design Patterns
- **MVVM** with `@StateObject` / `@ObservedObject`
- **Actors** for thread-safe services (`ScanEngine`, `FileOperationService`)
- **Combine** for reactive data binding
- **Async/await** throughout
- **Dependency injection** via environment objects

## Building

```bash
cd MacPulse
swift build
```

### Release Build
```bash
swift build -c release
```

### Run Tests
```bash
swift test
```

## Xcode Project Setup

To build as a native macOS app with full capabilities:

1. Open Xcode and create a new macOS App project named "MacPulse"
2. Copy all source files from the `MacPulse/` directory into the Xcode project
3. Set deployment target to macOS 13.0
4. Add required entitlements (see below)
5. Configure signing with your Developer ID

### Entitlements

Create `MacPulse.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

Note: Full disk access features require the app to run outside the sandbox or with appropriate temporary entitlements during development. For App Store distribution, specific capabilities must be requested.

## Code Signing & Notarization

```bash
# Sign with Developer ID
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --options runtime \
    MacPulse.app

# Create DMG
hdiutil create -volname "MacPulse" -srcfolder MacPulse.app \
    -ov -format UDZO MacPulse.dmg

# Notarize
xcrun notarytool submit MacPulse.dmg \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# Staple
xcrun stapler staple MacPulse.dmg
```

## Security

MacPulse implements multiple layers of protection:

- **Protected path whitelist** - System files, keychains, SSH keys, and user documents are never deleted
- **Protected file extensions** - `.keychain`, `.pem`, `.key`, `.cert`, `.p12` files are blocked
- **Running app detection** - Cannot delete bundles of currently running applications
- **Protected system services** - Critical macOS daemons cannot be disabled
- **Deletion logging** - All file operations are logged with timestamps
- **Batch validation** - Every file in a deletion batch is individually verified before removal

## Monetization

Implements StoreKit 2 with:
- Free tier with basic scanning
- 7-day free trial
- Monthly ($4.99) and yearly ($29.99) subscription options
- Receipt validation and entitlement checking

## License

Proprietary - All rights reserved.
