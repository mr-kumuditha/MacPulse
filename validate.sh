#!/bin/bash
# MacPulse Local Validation Script
# Runs WITHOUT Xcode - checks structure, syntax patterns, imports, and dependencies
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_DIR="$PROJECT_DIR/MacPulse"
PASS=0
FAIL=0
WARN=0

green()  { printf "\033[32m%s\033[0m\n" "$1"; }
red()    { printf "\033[31m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
bold()   { printf "\033[1m%s\033[0m\n" "$1"; }

check_pass() { PASS=$((PASS + 1)); green "  PASS: $1"; }
check_fail() { FAIL=$((FAIL + 1)); red   "  FAIL: $1"; }
check_warn() { WARN=$((WARN + 1)); yellow "  WARN: $1"; }

# ──────────────────────────────────────────────
bold "═══════════════════════════════════════════"
bold "  MacPulse Project Validator v1.0"
bold "  No Xcode required"
bold "═══════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────
bold "1. PROJECT STRUCTURE"
echo ""

REQUIRED_DIRS=(
    "App" "Models" "ViewModels" "Views" "Services" "Utilities" "Resources"
    "Views/Dashboard" "Views/Scanner" "Views/Duplicates" "Views/Storage"
    "Views/Monitor" "Views/Startup" "Views/Uninstaller" "Views/Privacy"
    "Views/Settings" "Views/MenuBar" "Views/Premium"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$SWIFT_DIR/$dir" ]; then
        check_pass "Directory: $dir"
    else
        check_fail "Missing directory: $dir"
    fi
done

# ──────────────────────────────────────────────
echo ""
bold "2. REQUIRED FILES"
echo ""

REQUIRED_FILES=(
    "App/MacPulseApp.swift"
    "App/AppDelegate.swift"
    "App/AppState.swift"
    "App/ContentView.swift"
    "Models/ScanResult.swift"
    "Models/CleaningCategory.swift"
    "Models/DuplicateFile.swift"
    "Models/SystemMetrics.swift"
    "Models/StartupItem.swift"
    "Models/InstalledApp.swift"
    "Models/LargeFile.swift"
    "Models/SubscriptionTier.swift"
    "Models/PrivacyItem.swift"
    "Services/ScanEngine.swift"
    "Services/DuplicateFinderService.swift"
    "Services/LargeFileAnalyzer.swift"
    "Services/SystemMonitor.swift"
    "Services/StartupManagerService.swift"
    "Services/AppUninstallerService.swift"
    "Services/PrivacyCleanerService.swift"
    "Services/AutomationEngine.swift"
    "Services/SafetyManager.swift"
    "Services/FileOperationService.swift"
    "Services/LicenseManager.swift"
    "Utilities/Logger.swift"
    "ViewModels/DashboardViewModel.swift"
    "ViewModels/ScanViewModel.swift"
    "ViewModels/DuplicateFinderViewModel.swift"
    "ViewModels/StorageViewModel.swift"
    "ViewModels/StartupManagerViewModel.swift"
    "ViewModels/UninstallerViewModel.swift"
    "ViewModels/PrivacyViewModel.swift"
    "Views/Dashboard/DashboardView.swift"
    "Views/Scanner/ScanView.swift"
    "Views/Duplicates/DuplicateFinderView.swift"
    "Views/Storage/StorageAnalyzerView.swift"
    "Views/Monitor/SystemMonitorView.swift"
    "Views/Startup/StartupManagerView.swift"
    "Views/Uninstaller/AppUninstallerView.swift"
    "Views/Privacy/PrivacyCleanerView.swift"
    "Views/Settings/SettingsView.swift"
    "Views/MenuBar/MenuBarView.swift"
    "Views/Premium/PremiumUpgradeView.swift"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SWIFT_DIR/$file" ]; then
        check_pass "$file"
    else
        check_fail "Missing: $file"
    fi
done

# ──────────────────────────────────────────────
echo ""
bold "3. SWIFT SYNTAX VALIDATION"
echo ""

# Check for balanced braces in each file
BRACE_ERRORS=0
while IFS= read -r file; do
    OPEN=$(grep -o "{" "$file" | wc -l | tr -d ' ')
    CLOSE=$(grep -o "}" "$file" | wc -l | tr -d ' ')
    if [ "$OPEN" != "$CLOSE" ]; then
        check_fail "Unbalanced braces in $(basename "$file"): { $OPEN vs } $CLOSE"
        BRACE_ERRORS=$((BRACE_ERRORS + 1))
    fi
done < <(find "$SWIFT_DIR" -name "*.swift" -type f)
if [ "$BRACE_ERRORS" -eq 0 ]; then
    check_pass "All files have balanced braces"
fi

# Check for @main entry point
if grep -rl "@main" "$SWIFT_DIR" > /dev/null 2>&1; then
    check_pass "@main entry point found"
else
    check_fail "No @main entry point"
fi

# Check for required patterns
if grep -rl "struct.*App.*:.*App" "$SWIFT_DIR" > /dev/null 2>&1; then
    check_pass "SwiftUI App protocol conformance found"
else
    check_fail "Missing App protocol conformance"
fi

# ──────────────────────────────────────────────
echo ""
bold "4. IMPORT ANALYSIS"
echo ""

echo "  Framework imports used:"
grep -rh "^import " "$SWIFT_DIR" --include="*.swift" | sort | uniq -c | sort -rn | while read count framework; do
    printf "    %3d × %s\n" "$count" "$framework"
done

# Check for forbidden imports
if grep -r "import UIKit" "$SWIFT_DIR" --include="*.swift" > /dev/null 2>&1; then
    check_fail "UIKit imported in macOS project"
else
    check_pass "No UIKit imports (correct for macOS)"
fi

if grep -r "import SwiftUI" "$SWIFT_DIR" --include="*.swift" > /dev/null 2>&1; then
    check_pass "SwiftUI framework used"
fi

if grep -r "import AppKit" "$SWIFT_DIR" --include="*.swift" > /dev/null 2>&1; then
    check_pass "AppKit framework used (native macOS)"
fi

if grep -r "import Combine" "$SWIFT_DIR" --include="*.swift" > /dev/null 2>&1; then
    check_pass "Combine framework used (reactive)"
fi

if grep -r "import StoreKit" "$SWIFT_DIR" --include="*.swift" > /dev/null 2>&1; then
    check_pass "StoreKit framework used (monetization)"
fi

# ──────────────────────────────────────────────
echo ""
bold "5. ARCHITECTURE VALIDATION"
echo ""

# MVVM checks
VM_COUNT=$(find "$SWIFT_DIR/ViewModels" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
VIEW_COUNT=$(find "$SWIFT_DIR/Views" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
SERVICE_COUNT=$(find "$SWIFT_DIR/Services" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
MODEL_COUNT=$(find "$SWIFT_DIR/Models" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')

echo "  Layer breakdown:"
echo "    Models:     $MODEL_COUNT files"
echo "    Views:      $VIEW_COUNT files"
echo "    ViewModels: $VM_COUNT files"
echo "    Services:   $SERVICE_COUNT files"

if [ "$VM_COUNT" -ge 5 ]; then check_pass "Sufficient ViewModels ($VM_COUNT)"; else check_fail "Too few ViewModels ($VM_COUNT)"; fi
if [ "$VIEW_COUNT" -ge 8 ]; then check_pass "Sufficient Views ($VIEW_COUNT)"; else check_fail "Too few Views ($VIEW_COUNT)"; fi
if [ "$SERVICE_COUNT" -ge 8 ]; then check_pass "Sufficient Services ($SERVICE_COUNT)"; else check_fail "Too few Services ($SERVICE_COUNT)"; fi
if [ "$MODEL_COUNT" -ge 6 ]; then check_pass "Sufficient Models ($MODEL_COUNT)"; else check_fail "Too few Models ($MODEL_COUNT)"; fi

# Check for ObservableObject / @Published patterns
OO_COUNT=$(grep -rl "ObservableObject" "$SWIFT_DIR" --include="*.swift" | wc -l | tr -d ' ')
PUB_COUNT=$(grep -rh "@Published" "$SWIFT_DIR" --include="*.swift" | wc -l | tr -d ' ')
echo ""
echo "  Reactive patterns:"
echo "    ObservableObject conformances: $OO_COUNT"
echo "    @Published properties: $PUB_COUNT"

if [ "$OO_COUNT" -ge 5 ]; then check_pass "Good ObservableObject usage"; else check_warn "Few ObservableObject classes"; fi
if [ "$PUB_COUNT" -ge 15 ]; then check_pass "Good @Published usage ($PUB_COUNT)"; else check_warn "Few @Published properties"; fi

# Actor usage
ACTOR_COUNT=$(grep -rl "^actor " "$SWIFT_DIR" --include="*.swift" | wc -l | tr -d ' ')
echo "    Actor services: $ACTOR_COUNT"
if [ "$ACTOR_COUNT" -ge 3 ]; then check_pass "Thread-safe actor services ($ACTOR_COUNT)"; else check_warn "Few actor services"; fi

# async/await
ASYNC_COUNT=$(grep -rh "async " "$SWIFT_DIR" --include="*.swift" | wc -l | tr -d ' ')
echo "    async functions: $ASYNC_COUNT"
if [ "$ASYNC_COUNT" -ge 10 ]; then check_pass "Modern concurrency adopted ($ASYNC_COUNT async funcs)"; else check_warn "Limited async usage"; fi

# ──────────────────────────────────────────────
echo ""
bold "6. SECURITY CHECKS"
echo ""

# Check SafetyManager exists and has protections
if grep -q "protectedPaths" "$SWIFT_DIR/Services/SafetyManager.swift" 2>/dev/null; then
    check_pass "SafetyManager has protected paths"
else
    check_fail "SafetyManager missing protected paths"
fi

if grep -q "protectedExtensions" "$SWIFT_DIR/Services/SafetyManager.swift" 2>/dev/null; then
    check_pass "SafetyManager has protected file extensions"
else
    check_fail "SafetyManager missing protected extensions"
fi

if grep -q "protectedBundleIDs" "$SWIFT_DIR/Services/SafetyManager.swift" 2>/dev/null; then
    check_pass "SafetyManager has protected bundle IDs"
else
    check_fail "SafetyManager missing protected bundle IDs"
fi

if grep -q "isSafeToDelete" "$SWIFT_DIR/Services/SafetyManager.swift" 2>/dev/null; then
    check_pass "SafetyManager validates deletions"
else
    check_fail "SafetyManager missing deletion validation"
fi

# Check FileOperationService routes through SafetyManager
if grep -q "safetyManager" "$SWIFT_DIR/Services/FileOperationService.swift" 2>/dev/null; then
    check_pass "FileOperationService uses SafetyManager"
else
    check_fail "FileOperationService bypasses SafetyManager"
fi

# Check for hardcoded secrets
if grep -rE "(password|secret|api_key|apikey)\s*=\s*\"[^\"]+\"" "$SWIFT_DIR" --include="*.swift" -i > /dev/null 2>&1; then
    check_fail "Potential hardcoded secrets found!"
else
    check_pass "No hardcoded secrets detected"
fi

# Check for force unwraps in services
FORCE_UNWRAP=$(grep -rn "!" "$SWIFT_DIR/Services" --include="*.swift" | grep -v "//" | grep -v "Bool" | grep -v "!=" | grep -c "\![^=]" || true)
if [ "$FORCE_UNWRAP" -lt 5 ]; then
    check_pass "Minimal force unwraps in services ($FORCE_UNWRAP)"
else
    check_warn "Multiple force unwraps in services ($FORCE_UNWRAP)"
fi

# ──────────────────────────────────────────────
echo ""
bold "7. FEATURE COMPLETENESS"
echo ""

FEATURES=(
    "ScanEngine:Smart Clean"
    "DuplicateFinderService:Duplicate Finder"
    "LargeFileAnalyzer:Storage Analyzer"
    "SystemMonitor:System Monitor"
    "StartupManagerService:Startup Manager"
    "AppUninstallerService:App Uninstaller"
    "PrivacyCleanerService:Privacy Cleaner"
    "AutomationEngine:Automation"
    "LicenseManager:Monetization"
    "MenuBarView:Menu Bar Widget"
)

for entry in "${FEATURES[@]}"; do
    FILE="${entry%%:*}"
    NAME="${entry##*:}"
    if find "$SWIFT_DIR" -name "${FILE}.swift" | grep -q .; then
        check_pass "$NAME"
    else
        check_fail "$NAME (missing $FILE)"
    fi
done

# ──────────────────────────────────────────────
echo ""
bold "8. TEST COVERAGE"
echo ""

TEST_DIR="$PROJECT_DIR/MacPulseTests"
if [ -d "$TEST_DIR" ]; then
    TEST_FILES=$(find "$TEST_DIR" -name "*.swift" | wc -l | tr -d ' ')
    TEST_FUNCS=$(grep -rh "func test" "$TEST_DIR" --include="*.swift" | wc -l | tr -d ' ')
    echo "  Test files: $TEST_FILES"
    echo "  Test functions: $TEST_FUNCS"
    if [ "$TEST_FUNCS" -ge 10 ]; then check_pass "Good test coverage ($TEST_FUNCS tests)"; else check_warn "Limited tests ($TEST_FUNCS)"; fi
else
    check_fail "No test directory found"
fi

# ──────────────────────────────────────────────
echo ""
bold "9. PACKAGE.SWIFT VALIDATION"
echo ""

if [ -f "$PROJECT_DIR/Package.swift" ]; then
    check_pass "Package.swift exists"

    if grep -q "macOS(.v13)" "$PROJECT_DIR/Package.swift"; then
        check_pass "Targets macOS 13+"
    else
        check_warn "macOS 13 platform not specified"
    fi

    if grep -q "executableTarget" "$PROJECT_DIR/Package.swift"; then
        check_pass "Executable target defined"
    else
        check_fail "No executable target"
    fi

    if grep -q "testTarget" "$PROJECT_DIR/Package.swift"; then
        check_pass "Test target defined"
    else
        check_warn "No test target"
    fi
else
    check_fail "Package.swift missing"
fi

# ──────────────────────────────────────────────
echo ""
bold "10. FILE SIZE ANALYSIS"
echo ""

TOTAL_LINES=$(find "$SWIFT_DIR" -name "*.swift" -exec cat {} + | wc -l | tr -d ' ')
TOTAL_FILES=$(find "$SWIFT_DIR" -name "*.swift" | wc -l | tr -d ' ')
echo "  Total Swift files: $TOTAL_FILES"
echo "  Total lines of code: $TOTAL_LINES"
echo "  Average lines per file: $((TOTAL_LINES / TOTAL_FILES))"
echo ""
echo "  Largest files:"
find "$SWIFT_DIR" -name "*.swift" -exec wc -l {} + | sort -rn | head -6 | tail -5 | while read lines file; do
    printf "    %4d lines  %s\n" "$lines" "$(basename "$file")"
done

# ══════════════════════════════════════════════
echo ""
bold "═══════════════════════════════════════════"
bold "  RESULTS"
bold "═══════════════════════════════════════════"
echo ""
green "  Passed: $PASS"
if [ "$WARN" -gt 0 ]; then yellow "  Warnings: $WARN"; fi
if [ "$FAIL" -gt 0 ]; then red "  Failed: $FAIL"; fi
echo ""

if [ "$FAIL" -eq 0 ]; then
    green "  All checks passed! Ready for cloud build."
else
    red "  $FAIL check(s) failed. Fix issues above."
    exit 1
fi
