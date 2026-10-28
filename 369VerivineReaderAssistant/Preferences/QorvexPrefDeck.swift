import StoreKit
import SwiftUI

struct QorvexPrefDeck: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    folioPrefRow("Rate Us", mark: "qorvex.rate", action: rateApp)
                    folioPrefRow("Privacy Policy", mark: "qorvex.privacy", action: VeyraLinkHarbor.openPrivacy)
                    folioPrefRow("Terms", mark: "qorvex.terms", action: VeyraLinkHarbor.openTerms)
                }
                Section {
                    Button {
                        confirmReset = true
                    } label: {
                        Text("Reset All Data")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .listRowBackground(Color.brindleCard)
                    .accessibilityIdentifier("qorvex.reset")
                } footer: {
                    Text("Circles, gatherings, titles, and notes stay on this device until you reset them.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .quillKeyboardDone()
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .alert("Reset all data?", isPresented: $confirmReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { vault.resetAll() }
            } message: {
                Text("Circles, gatherings, titles, and notes stored on this device will be removed.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func folioPrefRow(_ title: String, mark: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color.brindleCard)
        .accessibilityIdentifier(mark)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

enum QvMantleQorvexPrefDeckab049 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 6
        let tape = [15, 18, 7, 8]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-142-\(span % 15)")
    }
}
