import Foundation
import StoreKit
import Combine

@MainActor
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published var currentTier: SubscriptionTier = .free
    @Published var showUpgradeSheet = false
    @Published var trialExpiresAt: Date?
    @Published var isProcessingPurchase = false

    private let trialDays = 7
    private var updateListener: Task<Void, Error>?

    var isPremium: Bool {
        currentTier == .premium || (currentTier == .trial && !isTrialExpired)
    }

    var isTrialExpired: Bool {
        guard let expiry = trialExpiresAt else { return true }
        return Date() > expiry
    }

    var trialDaysRemaining: Int {
        guard let expiry = trialExpiresAt else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0)
    }

    private init() {
        loadState()
        listenForTransactions()
    }

    func hasAccess(to feature: PremiumFeature) -> Bool {
        if feature.isFree { return true }
        return isPremium
    }

    func startTrial() {
        guard trialExpiresAt == nil else { return }
        trialExpiresAt = Calendar.current.date(byAdding: .day, value: trialDays, to: Date())
        currentTier = .trial
        saveState()
        Logger.shared.info("Trial started, expires: \(trialExpiresAt!)", category: .license)
    }

    func purchase() async {
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            let products = try await Product.products(for: ["com.macpulse.pro.monthly", "com.macpulse.pro.yearly"])
            guard let product = products.first else {
                Logger.shared.error("No products found", category: .license)
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    currentTier = .premium
                    saveState()
                    await transaction.finish()
                    Logger.shared.info("Purchase successful", category: .license)
                case .unverified:
                    Logger.shared.error("Transaction unverified", category: .license)
                }
            case .userCancelled:
                break
            case .pending:
                Logger.shared.info("Purchase pending", category: .license)
            @unknown default:
                break
            }
        } catch {
            Logger.shared.error("Purchase failed: \(error)", category: .license)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            Logger.shared.error("Restore failed: \(error)", category: .license)
        }
    }

    private func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID.contains("macpulse.pro") {
                    currentTier = .premium
                    saveState()
                    return
                }
            }
        }
    }

    private func listenForTransactions() {
        updateListener = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID.contains("macpulse.pro") {
                        await MainActor.run {
                            currentTier = .premium
                            saveState()
                        }
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func loadState() {
        if let tier = UserDefaults.standard.string(forKey: "subscription_tier"),
           let t = SubscriptionTier(rawValue: tier) {
            currentTier = t
        }
        trialExpiresAt = UserDefaults.standard.object(forKey: "trial_expires") as? Date

        if currentTier == .trial && isTrialExpired {
            currentTier = .free
            saveState()
        }
    }

    private func saveState() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "subscription_tier")
        if let expiry = trialExpiresAt {
            UserDefaults.standard.set(expiry, forKey: "trial_expires")
        }
    }
}
