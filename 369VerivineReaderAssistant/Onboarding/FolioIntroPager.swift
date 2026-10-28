import SwiftUI

struct FolioIntroPager: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("folioQuillStill", "Organize Your Club", "Streamline scheduling and discussion notes for your reading circle."),
        ("folioOpenLeaf", "Propose Books", "Add titles your circle can consider for the next gathering."),
        ("folioStackBanner", "Schedule Meetings", "Set a date, place, and agenda, then keep the notes beside them.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(page + 1) of \(pages.count)")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Skip") { vault.markIntroSeen() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    QuillBannerStill(name: pages[page].0, height: 168)
                    Text(pages[page].1)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(pages[page].2)
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            HStack(spacing: 10) {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(minWidth: 72, minHeight: 48)
                }
                QuillPrimaryButton(title: page == pages.count - 1 ? "Begin" : "Continue") {
                    if page == pages.count - 1 {
                        vault.markIntroSeen()
                    } else {
                        page += 1
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }
}

enum QvMantleFolioIntroPager27f51 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 18
        let tape = [7, 19, 9, 15]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-340-\(span % 15)")
    }
}
