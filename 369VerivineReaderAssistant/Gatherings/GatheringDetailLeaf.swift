import SwiftUI

struct GatheringDetailLeaf: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let gatheringID: UUID
    @State private var editor: GatheringEditToken?
    @State private var noteEditor: MarginEditToken?
    @State private var confirmDelete = false
    @State private var score: Int?
    @State private var verdict = ""
    @State private var finishTitle = false
    @State private var verdictFault: String?
    @State private var loadedVerdict = false

    var body: some View {
        Group {
            if let item = vault.gathering(id: gatheringID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        QuillPaperCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.heldOn >= Date() ? "Upcoming" : "Past")
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                Text(QuillDateInk.medium(item.heldOn))
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                Text(item.placeLabel)
                                    .font(.system(size: 17, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                if let host = vault.circle(id: item.circleID)?.hostName {
                                    Text("Host · \(host)")
                                        .font(.system(size: 15, weight: .semibold, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                }
                            }
                        }
                        Text("Agenda")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                        if item.agendaMarks.isEmpty {
                            Text(item.agendaNote)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        } else {
                            ForEach(item.agendaMarks) { mark in
                                Button {
                                    if vault.toggleAgendaMark(gatheringID: item.id, markID: mark.id) {
                                        QuillTap.confirm()
                                    }
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: mark.done ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.primary)
                                        Text(mark.line)
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundColor(.primary)
                                            .strikethrough(mark.done)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(nil)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if let slipID = item.linkedSlipID, let slip = vault.slip(id: slipID) {
                            NavigationLink {
                                PloomSlipDetail(slipID: slip.id)
                            } label: {
                                QuillPaperCard {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Title on this gathering")
                                            .font(.system(size: 12, weight: .semibold, design: .serif))
                                            .foregroundColor(.secondary)
                                        Text(slip.title)
                                            .font(.system(size: 18, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        Text(slip.authorLine)
                                            .font(.system(size: 15, design: .serif))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                        Text(slip.readingLane.folioLabel)
                                            .font(.system(size: 14, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        if !slip.stopMark.isEmpty {
                                            Text("Read to \(slip.stopMark)")
                                                .font(.system(size: 15, design: .serif))
                                                .foregroundColor(.primary)
                                                .lineLimit(nil)
                                        }
                                        if slip.endingClosed {
                                            Text("Ending stays closed")
                                                .font(.system(size: 14, design: .serif))
                                                .foregroundColor(.secondary)
                                                .lineLimit(nil)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("No title is attached yet. Edit the gathering to choose one from the shelf.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        Text("Discussion notes")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                        let notes = vault.leaves(for: item.id)
                        if notes.isEmpty {
                            Text("No notes for this gathering yet.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        } else {
                            ForEach(notes) { note in
                                noteRow(note, gatheringID: item.id)
                            }
                        }
                        if item.heldOn >= Date() {
                            QuillPrimaryButton(title: "Log discussion points") {
                                noteEditor = MarginEditToken(existingID: nil, presetGatheringID: item.id)
                            }
                        }
                        verdictBlock(item, saveIsPrimary: item.heldOn < Date())
                        if item.heldOn < Date() {
                            QuillQuietButton(title: "Log discussion points") {
                                noteEditor = MarginEditToken(existingID: nil, presetGatheringID: item.id)
                            }
                        }
                    }
                    .padding(16)
                }
                .onAppear { loadVerdict(item) }
            } else {
                QuillEmptyMark(
                    symbol: "calendar",
                    title: "Gathering missing",
                    detail: "This gathering is no longer stored on the device."
                )
            }
        }
        .navigationTitle("Gathering")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            if let item = vault.gathering(id: gatheringID) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Schedule the next one") {
                            editor = nextToken(for: item)
                        }
                        Button("Edit gathering") {
                            editor = GatheringEditToken(existingID: item.id, presetSlipID: nil)
                        }
                        Button("Delete gathering", role: .destructive) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Gathering actions")
                }
            }
        }
        .sheet(item: $editor) { token in
            GatheringComposerSheet(token: token)
        }
        .sheet(item: $noteEditor) { token in
            NexilMarginEditor(token: token)
        }
        .alert("Delete this gathering?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if vault.deleteGathering(gatheringID) {
                    QuillTap.confirm()
                    dismiss()
                }
            }
        } message: {
            Text("The agenda and any notes tied to this gathering will be removed.")
        }
    }

    @ViewBuilder
    private func noteRow(_ note: NexilMarginLeaf, gatheringID: UUID) -> some View {
        if note.spoilerSealed {
            QuillPaperCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.title)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                    Text("Closed until chapter \(note.spoilerChapter)")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    Button("Show note") {
                        if vault.liftSpoiler(note.id) { QuillTap.confirm() }
                    }
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                    .frame(minHeight: 44)
                }
            }
        } else {
            Button {
                noteEditor = MarginEditToken(existingID: note.id, presetGatheringID: gatheringID)
            } label: {
                QuillPaperCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                        if !note.pageLabel.isEmpty {
                            Text(note.pageLabel)
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        Text(note.previewLine)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func verdictBlock(_ item: BrindleGatheringSlip, saveIsPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Circle verdict")
                .font(.system(size: 18, weight: .semibold, design: .serif))
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        score = score == value ? nil : value
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(score == value ? .black : .primary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(score == value ? Color.brindleInk : Color.brindleCard.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Score \(value)")
                }
            }
            QuillLineField(caption: "What the circle decided", text: $verdict, fault: verdictFault)
            if let slipID = item.linkedSlipID, let slip = vault.slip(id: slipID), slip.readingLane != .done {
                Toggle("Mark this title finished", isOn: $finishTitle)
                    .font(.system(size: 16, design: .serif))
                    .tint(Color.brindleRibbon)
            }
            if saveIsPrimary {
                QuillPrimaryButton(title: "Save verdict") {
                    saveVerdict(for: item)
                }
            } else {
                QuillQuietButton(title: "Save verdict") {
                    saveVerdict(for: item)
                }
            }
        }
    }

    private func loadVerdict(_ item: BrindleGatheringSlip) {
        guard !loadedVerdict else { return }
        loadedVerdict = true
        score = item.clubScore
        verdict = item.verdictLine
    }

    private func saveVerdict(for item: BrindleGatheringSlip) {
        let missing = score == nil && BrindleFieldCheck.trimmed(verdict).isEmpty
        verdictFault = missing ? "Add a score or a line about what the circle decided." : nil
        guard !missing else { return }
        if vault.saveVerdict(
            gatheringID: item.id,
            score: score,
            line: verdict,
            finishLinkedTitle: finishTitle
        ) {
            QuillTap.confirm()
            finishTitle = false
        }
    }

    private func nextToken(for item: BrindleGatheringSlip) -> GatheringEditToken {
        let queued = vault.slips(for: item.circleID)
            .filter { $0.readingLane == .queue }
            .sorted { $0.createdAt < $1.createdAt }
            .first?.id
        let linked = item.linkedSlipID.flatMap { vault.slip(id: $0) }
        let nextSlipID = (linked == nil || linked?.readingLane == .done) ? (queued ?? item.linkedSlipID) : linked?.id
        let copied = item.agendaMarks.map { BrindleAgendaMark(id: UUID(), line: $0.line, done: false) }
        let fallback = BrindleFieldCheck.lines(from: item.agendaNote).map {
            BrindleAgendaMark(id: UUID(), line: $0, done: false)
        }
        return GatheringEditToken(
            existingID: nil,
            presetSlipID: nextSlipID,
            presetHeldOn: Calendar.current.date(byAdding: .day, value: 7, to: item.heldOn) ?? item.heldOn,
            presetPlace: item.placeLabel,
            presetMarks: copied.isEmpty ? fallback : copied
        )
    }
}

enum QvMantleGatheringDetailLeaf9f05e {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 14
        let tape = [6, 6, 14, 14]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-505-\(span % 22)")
    }
}
