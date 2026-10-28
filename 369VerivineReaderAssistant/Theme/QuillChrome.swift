import SwiftUI
import UIKit

struct QuillBackdrop: View {
    var body: some View {
        Color.brindlePaper
            .overlay {
                Image("folioNookBackdrop")
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.brindlePaper.opacity(0.66),
                        Color.brindlePaper.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }
}

struct QuillHostClear: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            var node: UIView? = uiView.superview
            var hops = 0
            while let current = node, hops < 8, !(current is UIWindow) {
                current.backgroundColor = .clear
                node = current.superview
                hops += 1
            }
        }
    }
}

extension View {
    func quillLaidPaper() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbarBackground(Color.brindleCard, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background { QuillBackdrop() }
            .background { QuillHostClear() }
    }
}

struct QuillBannerStill: View {
    let name: String
    var height: CGFloat = 118

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(name)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct QuillPaperCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.brindleCard.opacity(0.96))
            )
    }
}

struct QuillPrimaryButton: View {
    let title: String
    var identifier: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(Color.brindleInk)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier ?? title)
    }
}

struct QuillQuietButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.brindleRibbon)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

struct QuillLineField: View {
    let caption: String
    @Binding var text: String
    var fault: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(nil)
            TextField(caption, text: $text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.brindleCard.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(fault == nil ? Color.brindleRibbon.opacity(0.45) : Color.red, lineWidth: 1)
                )
            if let fault {
                Text(fault)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct QuillAreaField: View {
    let caption: String
    @Binding var text: String
    var fault: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(nil)
            TextEditor(text: $text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.primary)
                .frame(minHeight: 110)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.brindleCard.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(fault == nil ? Color.brindleRibbon.opacity(0.45) : Color.red, lineWidth: 1)
                )
            if let fault {
                Text(fault)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct QuillEmptyMark: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Color.brindleRibbon)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            Text(detail)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.brindleCard.opacity(0.94))
        )
    }
}

struct BrindleBookmarkBar: View {
    @Binding var lane: Int

    private let lanes: [(String, String)] = [
        ("Meetings", "calendar"),
        ("Shelf", "books.vertical"),
        ("Notes", "note.text"),
        ("Pulse", "chart.bar")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(lanes.indices, id: \.self) { index in
                Button {
                    lane = index
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: lanes[index].1)
                            .font(.system(size: 20, weight: .semibold))
                        Text(lanes[index].0)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(lane == index ? Color.brindleRibbon : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lanes[index].0)
            }
        }
        .padding(.bottom, 4)
        .background(
            Color.brindleCard.opacity(0.96)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.brindleRibbon.opacity(0.35)).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct QuillOptionsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var openQuillOptions: () -> Void {
        get { self[QuillOptionsKey.self] }
        set { self[QuillOptionsKey.self] = newValue }
    }
}

struct QuillOptionsButton: View {
    @Environment(\.openQuillOptions) private var openQuillOptions

    var body: some View {
        Button(action: openQuillOptions) {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("Options")
    }
}

enum QvMantleQuillChromeac0e4 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 5
        let tape = [15, 4, 8, 19]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-704-\(span % 24)")
    }
}
