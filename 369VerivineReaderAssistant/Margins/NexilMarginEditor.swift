import SwiftUI

struct NexilMarginEditor: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let token: MarginEditToken
    @State private var gatheringID: UUID?
    @State private var title = ""
    @State private var points = ""
    @State private var quote = ""
    @State private var page = ""
    @State private var reaction = ""
    @State private var spoilerChapter = ""
    @State private var titleFault: String?
    @State private var bodyFault: String?
    @State private var gatheringFault: String?
    @State private var loaded = false
    @State private var confirmDiscard = false
    @State private var baseline = ""

    private var choices: [BrindleGatheringSlip] {
        guard let circleID = vault.activeCircleID else { return [] }
        return vault.gatherings(for: circleID).sorted { $0.heldOn > $1.heldOn }
    }

    private var snapshot: String {
        "\(gatheringID?.uuidString ?? "")|\(title)|\(points)|\(quote)|\(page)|\(reaction)|\(spoilerChapter)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if choices.isEmpty {
                        Text("Schedule a gathering before writing notes.")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    } else {
                        Text("Gathering")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(.secondary)
                        ForEach(choices) { item in
                            Button {
                                gatheringID = item.id
                            } label: {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(QuillDateInk.medium(item.heldOn))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        Text(item.placeLabel)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                    Spacer(minLength: 8)
                                    if gatheringID == item.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        if let gatheringFault {
                            Text(gatheringFault)
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(.red)
                                .lineLimit(nil)
                        }
                    }
                    QuillLineField(caption: "Note title", text: $title, fault: titleFault)
                    QuillAreaField(caption: "Quote", text: $quote, fault: nil)
                    QuillLineField(caption: "Page", text: $page, fault: nil)
                    QuillLineField(caption: "Reaction", text: $reaction, fault: nil)
                    QuillAreaField(caption: "Discussion points", text: $points, fault: bodyFault)
                    QuillLineField(caption: "Hide until chapter", text: $spoilerChapter, fault: nil)
                    Text("Leave the chapter blank to keep the note open. A chapter keeps the quote folded until you show it.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    QuillPrimaryButton(title: "Save note") { commit() }
                    QuillQuietButton(title: "Cancel") { requestClose() }
                }
                .padding(16)
            }
            .quillKeyboardDone()
            .navigationTitle(token.existingID == nil ? "New note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .quillLaidPaper()
            .onAppear(perform: load)
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("This note will stay as it was.")
            }
        }
        .interactiveDismissDisabled(loaded && snapshot != baseline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let existingID = token.existingID, let leaf = vault.leaf(id: existingID) {
            gatheringID = leaf.gatheringID
            title = leaf.title
            points = leaf.points
            quote = leaf.quoteLine
            page = leaf.pageLabel
            reaction = leaf.reaction
            spoilerChapter = leaf.spoilerChapter
        } else {
            gatheringID = token.presetGatheringID
        }
        baseline = snapshot
    }

    private func requestClose() {
        if snapshot != baseline { confirmDiscard = true } else { dismiss() }
    }

    private func commit() {
        gatheringFault = gatheringID == nil ? "Choose a gathering for this note." : nil
        titleFault = BrindleFieldCheck.required(title, hint: "Add a title for the note.")
        let hasBody = !BrindleFieldCheck.trimmed(points).isEmpty
            || !BrindleFieldCheck.trimmed(quote).isEmpty
            || !BrindleFieldCheck.trimmed(reaction).isEmpty
        bodyFault = hasBody ? nil : "Add a quote, a reaction, or a discussion point."
        guard gatheringFault == nil, titleFault == nil, bodyFault == nil, let gatheringID else { return }
        if vault.saveLeaf(
            existingID: token.existingID,
            gatheringID: gatheringID,
            title: title,
            points: points,
            quote: quote,
            page: page,
            reaction: reaction,
            spoilerChapter: spoilerChapter
        ) {
            QuillTap.confirm()
            dismiss()
        }
    }
}

enum QvMantleNexilMarginEditor7357b {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 18
        let tape = [19, 15, 16, 18]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-619-\(span % 15)")
    }
}
