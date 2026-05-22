import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow.gradient)

                Text("MacPulse Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Unlock the full power of Mac optimization")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            // Features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PremiumFeature.allCases.filter { !$0.isFree }) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: feature.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(feature.rawValue)
                                .font(.callout)
                                .fontWeight(.medium)
                            Text(feature.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 24)

            // Pricing
            HStack(spacing: 16) {
                PricingCard(
                    title: "Monthly",
                    price: "$4.99",
                    period: "/month",
                    isPopular: false
                ) {
                    Task { await licenseManager.purchase() }
                }

                PricingCard(
                    title: "Yearly",
                    price: "$29.99",
                    period: "/year",
                    isPopular: true,
                    savings: "Save 50%"
                ) {
                    Task { await licenseManager.purchase() }
                }
            }
            .padding(.horizontal, 24)

            // Trial / Restore
            VStack(spacing: 8) {
                if licenseManager.trialExpiresAt == nil {
                    Button("Start 7-Day Free Trial") {
                        licenseManager.startTrial()
                        dismiss()
                    }
                    .font(.headline)
                }

                Button("Restore Purchases") {
                    Task { await licenseManager.restorePurchases() }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Button("Not Now") {
                dismiss()
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Text("by \(AppInfo.developer)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
        .frame(width: 520, height: 640)
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    var savings: String?
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isPopular {
                Text("BEST VALUE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue)
                    .clipShape(Capsule())
            }

            Text(title)
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(price)
                    .font(.title)
                    .fontWeight(.bold)
                Text(period)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let savings {
                Text(savings)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .fontWeight(.semibold)
            }

            Button(action: action) {
                Text("Subscribe")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isPopular ? Color.blue : .clear, lineWidth: 2)
        )
    }
}
