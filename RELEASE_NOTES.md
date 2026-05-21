# MacPulse v1.0.0 Release Notes

## What's New

### Smart Clean Engine
- Intelligent scanning across 10 cleanup categories
- User cache, browser cache, Xcode DerivedData, temp files, Trash
- System logs, broken downloads, mail cache, app leftovers, iOS backups
- Categorized results with file previews and size breakdowns
- Safe deletion with confirmation and audit logging

### Duplicate Finder
- SHA-256 partial hashing for fast, accurate detection
- Groups duplicates with wasted space calculations
- Auto-select feature keeps the oldest (original) file
- Batch deletion with progress tracking

### Storage Analyzer
- Visual storage breakdown by directory
- Large file scanner with configurable minimum size
- Sort by size, date, or name
- Reveal in Finder integration
- Category classification (documents, media, archives, disk images)

### Real-time System Monitor
- Live CPU usage with history charts
- Memory pressure analysis (nominal/warning/critical)
- Disk usage visualization
- Top process list with CPU and memory stats
- 60-second rolling history

### Startup Manager
- LaunchAgent and LaunchDaemon management
- Toggle items on/off with system protection
- Filter by type (Login Items, Launch Agents, Launch Daemons)

### App Uninstaller
- Complete app removal with leftover detection
- Finds preferences, caches, containers, saved state, and logs
- App icon display with size information
- Search and sort capabilities

### Privacy Cleaner
- Safari, Chrome, Firefox, and Brave support
- Cleans history, cookies, cache, and session data
- Browser detection with availability indicators
- Selective cleaning by browser or category

### Automation Engine
- Scheduled cleaning (daily, weekly, bi-weekly, monthly)
- macOS notification integration
- Configurable cleaning categories per schedule

### Menu Bar App
- Always-accessible system overview
- Quick CPU, memory, and disk metrics
- One-click access to scanning and monitoring

### Monetization
- Free tier with Smart Clean and basic monitoring
- 7-day free trial for Pro features
- Monthly ($4.99) and yearly ($29.99) subscriptions via StoreKit 2

## System Requirements
- macOS 13.0 (Ventura) or later
- Intel or Apple Silicon Mac
- 50 MB disk space

## Known Limitations
- Network traffic monitoring not yet implemented
- Temperature sensing requires SMC access (not available in sandbox)
- iOS backup cleanup requires explicit user confirmation
