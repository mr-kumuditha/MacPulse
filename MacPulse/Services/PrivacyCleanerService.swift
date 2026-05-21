import Foundation

actor PrivacyCleanerService {
    static let shared = PrivacyCleanerService()

    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser.path

    func scanPrivacyItems() async -> [PrivacyItem] {
        var items: [PrivacyItem] = []

        for browser in Browser.allCases where browser.isInstalled {
            items.append(contentsOf: await scanBrowser(browser))
        }

        return items
    }

    private func scanBrowser(_ browser: Browser) async -> [PrivacyItem] {
        var items: [PrivacyItem] = []

        let paths = browserPaths(for: browser)

        for (category, pathList) in paths {
            for path in pathList {
                guard fileManager.fileExists(atPath: path) else { continue }
                let size = await FileOperationService.shared.directorySize(at: path)
                guard size > 0 else { continue }

                items.append(PrivacyItem(
                    browser: browser,
                    category: category,
                    path: path,
                    size: size
                ))
            }
        }

        return items
    }

    private func browserPaths(for browser: Browser) -> [PrivacyCategory: [String]] {
        switch browser {
        case .safari:
            return [
                .history: [
                    "\(home)/Library/Safari/History.db",
                    "\(home)/Library/Safari/History.db-wal"
                ],
                .cache: [
                    "\(home)/Library/Caches/com.apple.Safari",
                    "\(home)/Library/Safari/LocalStorage"
                ],
                .cookies: [
                    "\(home)/Library/Cookies/Cookies.binarycookies"
                ],
                .sessions: [
                    "\(home)/Library/Safari/LastSession.plist"
                ]
            ]

        case .chrome:
            let chromeBase = "\(home)/Library/Application Support/Google/Chrome/Default"
            return [
                .history: [
                    "\(chromeBase)/History",
                    "\(chromeBase)/History-journal"
                ],
                .cache: [
                    "\(home)/Library/Caches/Google/Chrome"
                ],
                .cookies: [
                    "\(chromeBase)/Cookies",
                    "\(chromeBase)/Cookies-journal"
                ],
                .sessions: [
                    "\(chromeBase)/Sessions",
                    "\(chromeBase)/Current Session",
                    "\(chromeBase)/Current Tabs"
                ]
            ]

        case .firefox:
            let ffBase = "\(home)/Library/Application Support/Firefox/Profiles"
            let profiles = (try? fileManager.contentsOfDirectory(atPath: ffBase)) ?? []
            let profilePath = profiles.first.map { "\(ffBase)/\($0)" } ?? ffBase

            return [
                .history: [
                    "\(profilePath)/places.sqlite"
                ],
                .cache: [
                    "\(home)/Library/Caches/Firefox/Profiles"
                ],
                .cookies: [
                    "\(profilePath)/cookies.sqlite"
                ],
                .sessions: [
                    "\(profilePath)/sessionstore.jsonlz4"
                ]
            ]

        case .brave:
            let braveBase = "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/Default"
            return [
                .history: [
                    "\(braveBase)/History"
                ],
                .cache: [
                    "\(home)/Library/Caches/BraveSoftware"
                ],
                .cookies: [
                    "\(braveBase)/Cookies"
                ],
                .sessions: [
                    "\(braveBase)/Sessions"
                ]
            ]
        }
    }

    func cleanItems(_ items: [PrivacyItem]) async -> FileOperationService.DeletionResult {
        let paths = items.filter(\.isSelected).map(\.path)
        return await FileOperationService.shared.deleteFiles(paths, category: "privacy")
    }
}
