import XCTest
@testable import MacPulse

final class SafetyManagerTests: XCTestCase {
    let safetyManager = SafetyManager.shared

    func testProtectedSystemPaths() {
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/System"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/System/Library"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/usr"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/bin"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/sbin"))
    }

    func testProtectedUserPaths() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/Documents"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/Desktop"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/.ssh"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/.ssh/id_rsa"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/Library/Keychains"))
    }

    func testProtectedFileExtensions() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/test.keychain"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/test.keychain-db"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/server.pem"))
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "\(home)/cert.p12"))
    }

    func testProtectedBundleIDs() {
        XCTAssertFalse(safetyManager.isSafeToDisable(bundleID: "com.apple.finder"))
        XCTAssertFalse(safetyManager.isSafeToDisable(bundleID: "com.apple.dock"))
        XCTAssertFalse(safetyManager.isSafeToDisable(bundleID: "com.apple.loginwindow"))
        XCTAssertTrue(safetyManager.isSafeToDisable(bundleID: "com.example.testapp"))
    }

    func testBatchValidation() {
        let paths = ["/System/test", "/tmp/testfile_nonexistent", "/nonexistent"]
        let result = safetyManager.validateBatchDeletion(paths: paths)
        XCTAssertTrue(result.blocked.contains("/System/test"))
    }

    func testNonExistentFileNotSafe() {
        XCTAssertFalse(safetyManager.isSafeToDelete(path: "/nonexistent/path/file.txt"))
    }
}

final class CleaningCategoryTests: XCTestCase {
    func testAllCategoriesHaveScanPaths() {
        for category in CleaningCategory.allCases {
            XCTAssertFalse(category.scanPaths.isEmpty, "\(category.rawValue) has no scan paths")
        }
    }

    func testAllCategoriesHaveIcons() {
        for category in CleaningCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) has no icon")
        }
    }

    func testAllCategoriesHaveDescriptions() {
        for category in CleaningCategory.allCases {
            XCTAssertFalse(category.description.isEmpty, "\(category.rawValue) has no description")
        }
    }
}

final class LargeFileCategoryTests: XCTestCase {
    func testCategorization() {
        XCTAssertEqual(LargeFileCategory.categorize(path: "/test/file.mp4"), .media)
        XCTAssertEqual(LargeFileCategory.categorize(path: "/test/file.zip"), .archives)
        XCTAssertEqual(LargeFileCategory.categorize(path: "/test/file.dmg"), .diskImages)
        XCTAssertEqual(LargeFileCategory.categorize(path: "/test/file.pdf"), .documents)
        XCTAssertEqual(LargeFileCategory.categorize(path: "/test/file.xyz"), .other)
    }
}

final class ScanResultTests: XCTestCase {
    func testFormattedSize() {
        let result = ScanResult(
            category: .userCache,
            path: "/tmp/test",
            fileSize: 1024 * 1024, // 1 MB
            fileName: "test",
            modificationDate: nil
        )
        XCTAssertFalse(result.formattedSize.isEmpty)
    }

    func testCategorySummaryTotalSize() {
        let results = [
            ScanResult(category: .userCache, path: "/a", fileSize: 100, fileName: "a", modificationDate: nil),
            ScanResult(category: .userCache, path: "/b", fileSize: 200, fileName: "b", modificationDate: nil)
        ]
        let summary = CategorySummary(category: .userCache, results: results)
        XCTAssertEqual(summary.totalSize, 300)
        XCTAssertEqual(summary.fileCount, 2)
    }
}

final class SubscriptionTests: XCTestCase {
    func testFreeTierFeatures() {
        let tier = SubscriptionTier.free
        XCTAssertTrue(tier.features.contains(.smartClean))
        XCTAssertTrue(tier.features.contains(.basicMonitor))
        XCTAssertFalse(tier.features.contains(.duplicateFinder))
    }

    func testPremiumTierFeatures() {
        let tier = SubscriptionTier.premium
        XCTAssertTrue(tier.features.contains(.duplicateFinder))
        XCTAssertTrue(tier.features.contains(.automation))
        XCTAssertTrue(tier.features.contains(.realtimeMonitor))
    }

    func testFreeFeatureIdentification() {
        XCTAssertTrue(PremiumFeature.smartClean.isFree)
        XCTAssertTrue(PremiumFeature.basicMonitor.isFree)
        XCTAssertFalse(PremiumFeature.duplicateFinder.isFree)
        XCTAssertFalse(PremiumFeature.automation.isFree)
    }
}

final class DuplicateFileTests: XCTestCase {
    func testDuplicateGroupWastedSpace() {
        let files = [
            DuplicateFile(path: "/a/file.txt", size: 1000, modificationDate: nil),
            DuplicateFile(path: "/b/file.txt", size: 1000, modificationDate: nil),
            DuplicateFile(path: "/c/file.txt", size: 1000, modificationDate: nil)
        ]
        let group = DuplicateGroup(hash: "abc123", files: files, fileSize: 1000)
        XCTAssertEqual(group.wastedSpace, 2000)
    }

    func testDuplicateFileName() {
        let file = DuplicateFile(path: "/Users/test/Documents/photo.jpg", size: 5000, modificationDate: nil)
        XCTAssertEqual(file.fileName, "photo.jpg")
        XCTAssertEqual(file.directory, "/Users/test/Documents")
    }
}

final class ScheduleTests: XCTestCase {
    func testFrequencyIntervals() {
        XCTAssertEqual(ScheduleFrequency.daily.interval, 86400)
        XCTAssertEqual(ScheduleFrequency.weekly.interval, 604800)
        XCTAssertEqual(ScheduleFrequency.monthly.interval, 2592000)
    }

    func testDefaultSchedule() {
        let schedule = CleaningSchedule()
        XCTAssertTrue(schedule.isEnabled)
        XCTAssertEqual(schedule.frequency, .weekly)
        XCTAssertEqual(schedule.categories.count, CleaningCategory.allCases.count)
    }
}
