import Foundation

enum AppInfo {
    static let name = "MacPulse"
    static let version = "1.0.0"
    static let build = "1"
    static let developer = "DevTharinda"
    static let copyright = "Copyright 2026 MacPulse. All rights reserved."
    static let bundleID = "com.macpulse.app"

    static var fullVersion: String {
        "\(version) (\(build))"
    }
}
