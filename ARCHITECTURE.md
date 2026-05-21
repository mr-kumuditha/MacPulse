# MacPulse Architecture Document

## Overview

MacPulse is a native macOS system optimization application built with Swift 5.9, SwiftUI, and modern concurrency (async/await, actors). It follows MVVM architecture with a service-oriented backend.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI + AppKit (where needed) |
| Architecture | MVVM |
| Concurrency | Swift Actors, async/await |
| Reactive | Combine |
| Persistence | UserDefaults, JSON files |
| Payments | StoreKit 2 |
| Monitoring | Mach kernel APIs, sysctl |
| Hashing | CommonCrypto (SHA-256) |
| Logging | os.log (unified logging) |

## Core Components

### 1. ScanEngine (Actor)
The central scanning engine that orchestrates file system scans across all cleaning categories. Uses `FileManager` enumerators with `async/await` for non-blocking scanning.

Key design decisions:
- **Actor isolation** prevents data races during concurrent scans
- **Configurable depth limits** per category to control scan scope
- **Progress callbacks** via `@Sendable` closures for UI updates

### 2. SafetyManager (Singleton)
Critical safety layer that validates every file operation. Maintains:
- Protected path whitelist (system dirs, user documents, SSH keys)
- Protected file extension list (keychains, certificates)
- Protected bundle identifier list (Finder, Dock, SystemUIServer)
- Deletion logging for audit trail

### 3. FileOperationService (Actor)
All file deletions route through this service, which:
1. Validates each path against SafetyManager
2. Records file sizes before deletion
3. Performs the deletion
4. Logs the operation
5. Returns aggregated results

### 4. SystemMonitor (ObservableObject)
Reads system metrics via Mach kernel APIs:
- CPU: `host_statistics` with `HOST_CPU_LOAD_INFO`
- Memory: `host_statistics64` with `HOST_VM_INFO64`
- Disk: `FileManager.attributesOfFileSystem`
- Processes: `ps` command output parsing

Updates every 2 seconds with history buffer (60 entries).

### 5. DuplicateFinderService (Actor)
Three-phase duplicate detection:
1. **Index** - Group files by size
2. **Hash** - SHA-256 partial hashing (first 64KB + middle + end chunks)
3. **Compare** - Group by hash, report duplicates

Partial hashing strategy provides >99.9% accuracy with ~10x speed improvement over full file hashing.

### 6. LicenseManager (MainActor)
StoreKit 2 integration handling:
- Product fetching and purchase flow
- Transaction verification
- Entitlement checking
- Trial period management
- Purchase restoration

## Data Flow

```
User Action → View → ViewModel → Service (Actor) → FileManager/System APIs
                ↑         ↓
                └── @Published properties (Combine) ──┘
```

## Threading Model

- **Main thread**: All ViewModels are `@MainActor`
- **Background**: Services are Swift Actors (thread-safe)
- **System Monitor**: Timer-based polling on main thread, process scanning on utility queue

## Security Architecture

```
Delete Request → FileOperationService
                     ↓
              SafetyManager.validateBatchDeletion()
                     ↓
              ┌─────────────┐
              │ Path check   │ → Protected paths → BLOCK
              │ Extension    │ → Protected exts  → BLOCK
              │ Running apps │ → Active bundle   → BLOCK
              │ Permissions  │ → Not deletable   → BLOCK
              └─────────────┘
                     ↓ (passed)
              FileManager.removeItem()
                     ↓
              Deletion logged to audit file
```

## Database Schema

No traditional database. Persistence uses:
- `UserDefaults` for app state, settings, subscription tier
- JSON files for deletion logs and automation schedules
- All stored in `~/Library/Application Support/MacPulse/`

## Performance Targets

| Metric | Target |
|--------|--------|
| App startup | < 2 seconds |
| Smart scan (full) | < 30 seconds |
| Duplicate scan (home dir) | < 2 minutes |
| Memory usage (idle) | < 50 MB |
| Memory usage (scanning) | < 150 MB |
| CPU usage (idle) | < 1% |

## Module Dependency Graph

```
Views → ViewModels → Services → Utilities
  ↓                     ↓           ↓
Models ←──────────── Models ←── Logger
```

No circular dependencies. Services depend only on Models and Utilities.
