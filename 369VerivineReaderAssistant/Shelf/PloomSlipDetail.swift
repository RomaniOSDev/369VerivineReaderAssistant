import SwiftUI

struct PloomSlipDetail: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let slipID: UUID
    @State private var editor: SlipEditToken?
    @State private var gatheringEditor: GatheringEditToken?
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let slip = vault.slip(id: slipID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        QuillPaperCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(slip.readingLane.folioLabel)
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                Text(slip.title)
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                Text(slip.authorLine)
                                    .font(.system(size: 17, design: .serif))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                if slip.chosen {
                                    Text("On a gathering")
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                }
                                if let suggested = vault.seatName(slip.suggestedBySeatID) {
                                    Text("Suggested by \(suggested)")
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                }
                                if !slip.stopMark.isEmpty {
                                    Text("Read to \(slip.stopMark)")
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                }
                                if slip.endingClosed {
                                    Text("Ending stays closed")
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                }
                                if !slip.pitchNote.isEmpty {
                                    Text(slip.pitchNote)
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                }
                            }
                        }
                        if slip.readingLane != .now {
                            QuillPrimaryButton(title: "Read this now") {
                                if vault.setReadingLane(slip.id, lane: .now) { QuillTap.confirm() }
                            }
                        } else if !slip.chosen {
                            QuillPrimaryButton(title: "Attach to a gathering") {
                                gatheringEditor = GatheringEditToken(existingID: nil, presetSlipID: slip.id)
                            }
                        }
                        let linked = vault.gatherings.filter { $0.linkedSlipID == slip.id }
                        if linked.isEmpty {
                            Text("This title is not on a gathering yet.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        } else {
                            Text("Used by")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                            ForEach(linked) { item in
                                NavigationLink {
                                    GatheringDetailLeaf(gatheringID: item.id)
                                } label: {
                                    QuillPaperCard {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(QuillDateInk.medium(item.heldOn))
                                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                                .foregroundColor(.primary)
                                                .lineLimit(nil)
                                            Text(item.placeLabel)
                                                .font(.system(size: 15, design: .serif))
                                                .foregroundColor(.secondary)
                                                .lineLimit(nil)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                QuillEmptyMark(
                    symbol: "books.vertical",
                    title: "Title missing",
                    detail: "This title is no longer stored on the device."
                )
            }
        }
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            if let slip = vault.slip(id: slipID) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !(slip.readingLane == .now && !slip.chosen) {
                            Button("Attach to a gathering") {
                                gatheringEditor = GatheringEditToken(existingID: nil, presetSlipID: slip.id)
                            }
                        }
                        if slip.readingLane != .queue {
                            Button("Return to the queue") {
                                if vault.setReadingLane(slip.id, lane: .queue) { QuillTap.confirm() }
                            }
                        }
                        if slip.readingLane != .done {
                            Button("Mark finished") {
                                if vault.setReadingLane(slip.id, lane: .done) { QuillTap.confirm() }
                            }
                        }
                        Button("Edit title") {
                            editor = SlipEditToken(existingID: slip.id)
                        }
                        Button("Delete title", role: .destructive) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Title actions")
                }
            }
        }
        .sheet(item: $editor) { token in
            PloomSlipComposer(token: token)
        }
        .sheet(item: $gatheringEditor) { token in
            GatheringComposerSheet(token: token)
        }
        .alert("Delete this title?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if vault.deleteSlip(slipID) {
                    QuillTap.confirm()
                    dismiss()
                }
            }
        } message: {
            Text("Gatherings that used this title will keep their agenda, without the link.")
        }
    }
}

enum QvMantlePloomSlipDetail2544d {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 19
        let tape = [7, 11, 13, 6]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 3)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-583-\(span % 22)")
    }
}
