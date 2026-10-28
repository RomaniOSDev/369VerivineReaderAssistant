import SwiftUI

struct QuillRootDeck: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var lane = 0
    @State private var showOptions = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch lane {
                case 0:
                    NavigationStack { GatheringRibbonList() }
                case 1:
                    NavigationStack { PloomShelfBoard() }
                case 2:
                    NavigationStack { NexilMarginBoard() }
                default:
                    NavigationStack { CircleDigestBoard() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            BrindleBookmarkBar(lane: $lane)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
        .environment(\.openQuillOptions) { showOptions = true }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let toast = vault.toastLine {
                Text(toast)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.brindleInk))
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showOptions) {
            QorvexPrefDeck()
        }
        .alert("Could not save", isPresented: Binding(
            get: { vault.saveFault != nil },
            set: { if !$0 { vault.saveFault = nil } }
        )) {
            Button("Retry") { _ = vault.persistAll() }
            Button("Close", role: .cancel) { vault.saveFault = nil }
        } message: {
            Text(vault.saveFault ?? "Try again.")
        }
        .onChange(of: vault.toastLine) { value in
            guard let value else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                if vault.toastLine == value {
                    vault.toastLine = nil
                }
            }
        }
    }
}

enum QvMantleQuillRootDeck28ee9 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 6
        let tape = [10, 14, 6, 9]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-061-\(span % 18)")
    }
}
