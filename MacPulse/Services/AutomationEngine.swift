import Foundation
import Combine
import UserNotifications

final class AutomationEngine: ObservableObject {
    static let shared = AutomationEngine()

    @Published var schedules: [CleaningSchedule] = []
    @Published var isRunning = false

    private var timer: Timer?
    private let storageKey = "cleaning_schedules"

    private init() {}

    func loadSchedules() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([CleaningSchedule].self, from: data) else {
            schedules = [CleaningSchedule()] // Default weekly schedule
            return
        }
        schedules = saved
        startScheduleChecker()
    }

    func saveSchedules() {
        guard let data = try? JSONEncoder().encode(schedules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func addSchedule(_ schedule: CleaningSchedule) {
        schedules.append(schedule)
        saveSchedules()
    }

    func removeSchedule(_ id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
    }

    func updateSchedule(_ schedule: CleaningSchedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[index] = schedule
        saveSchedules()
    }

    private func startScheduleChecker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
    }

    private func checkSchedules() {
        let now = Date()

        for index in schedules.indices {
            guard schedules[index].isEnabled else { continue }

            let shouldRun: Bool
            if let nextRun = schedules[index].nextRun {
                shouldRun = now >= nextRun
            } else {
                shouldRun = true
            }

            guard shouldRun else { continue }

            let categories = schedules[index].categories.compactMap { CleaningCategory(rawValue: $0) }
            runAutomatedClean(categories: categories, scheduleIndex: index)
        }
    }

    private func runAutomatedClean(categories: [CleaningCategory], scheduleIndex: Int) {
        guard !isRunning else { return }
        isRunning = true

        Task {
            let results = await ScanEngine.shared.scanAll(categories: categories) { _, _ in }

            var totalFreed: Int64 = 0
            for summary in results {
                let paths = summary.results.map(\.path)
                let result = await FileOperationService.shared.deleteFiles(paths, category: "automation")
                totalFreed += result.freedBytes
            }

            await MainActor.run {
                schedules[scheduleIndex].lastRun = Date()
                schedules[scheduleIndex].nextRun = Date().addingTimeInterval(
                    ScheduleFrequency(rawValue: schedules[scheduleIndex].frequency.rawValue)?.interval ?? 604800
                )
                saveSchedules()
                isRunning = false

                sendNotification(freedBytes: totalFreed)
            }
        }
    }

    private func sendNotification(freedBytes: Int64) {
        let content = UNMutableNotificationContent()
        content.title = "MacPulse Auto-Clean Complete"
        content.body = "Freed \(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)) of disk space."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
