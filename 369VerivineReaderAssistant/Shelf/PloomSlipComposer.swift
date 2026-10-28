import SwiftUI

struct PloomSlipComposer: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let token: SlipEditToken
    @State private var title = ""
    @State private var author = ""
    @State private var pitch = ""
    @State private var lane: PloomReadingLane = .queue
    @State private var stopMark = ""
    @State private var endingClosed = false
    @State private var suggestedBySeatID: UUID?
    @State private var titleFault: String?
    @State private var authorFault: String?
    @State private var loaded = false
    @State private var confirmDiscard = false
    @State private var baseline = ""

    private var seats: [BrindleSeat] {
        vault.activeCircle?.seats ?? []
    }

    private var snapshot: String {
        "\(title)|\(author)|\(pitch)|\(lane.rawValue)|\(stopMark)|\(endingClosed)|\(suggestedBySeatID?.uuidString ?? "")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    QuillLineField(caption: "Title", text: $title, fault: titleFault)
                    QuillLineField(caption: "Author", text: $author, fault: authorFault)
                    QuillAreaField(caption: "Why this title", text: $pitch, fault: nil)
                    Text("Reading")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    Picker("Reading", selection: $lane) {
                        Text("Queue").tag(PloomReadingLane.queue)
                        Text("Now").tag(PloomReadingLane.now)
                        Text("Done").tag(PloomReadingLane.done)
                    }
                    .pickerStyle(.segmented)
                    QuillLineField(caption: "Stop mark", text: $stopMark, fault: nil)
                    Text("A chapter or a page. This is as far as the circle reads before the gathering.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    Toggle("Keep the ending closed", isOn: $endingClosed)
                        .font(.system(size: 16, design: .serif))
                        .tint(Color.brindleRibbon)
                    if !seats.isEmpty {
                        Text("Suggested by")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(.secondary)
                        Button {
                            suggestedBySeatID = nil
                        } label: {
                            seatRow(title: "No one", selected: suggestedBySeatID == nil)
                        }
                        .buttonStyle(.plain)
                        ForEach(seats) { seat in
                            Button {
                                suggestedBySeatID = seat.id
                            } label: {
                                seatRow(title: seat.name, selected: suggestedBySeatID == seat.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    QuillPrimaryButton(title: "Save title") { commit() }
                    QuillQuietButton(title: "Cancel") { requestClose() }
                }
                .padding(16)
            }
            .quillKeyboardDone()
            .navigationTitle(token.existingID == nil ? "New title" : "Edit title")
            .navigationBarTitleDisplayMode(.inline)
            .quillLaidPaper()
            .onAppear(perform: load)
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("This title will stay as it was.")
            }
        }
        .interactiveDismissDisabled(loaded && snapshot != baseline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func seatRow(title: String, selected: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            Spacer(minLength: 8)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .frame(minHeight: 44)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let existingID = token.existingID, let slip = vault.slip(id: existingID) {
            title = slip.title
            author = slip.authorLine
            pitch = slip.pitchNote
            lane = slip.readingLane
            stopMark = slip.stopMark
            endingClosed = slip.endingClosed
            suggestedBySeatID = slip.suggestedBySeatID
        }
        baseline = snapshot
    }

    private func requestClose() {
        if snapshot != baseline { confirmDiscard = true } else { dismiss() }
    }

    private func commit() {
        titleFault = BrindleFieldCheck.required(title, hint: "Add the title.")
        authorFault = BrindleFieldCheck.required(author, hint: "Add the author.")
        guard titleFault == nil, authorFault == nil, let circleID = vault.activeCircleID else { return }
        if vault.saveSlip(
            existingID: token.existingID,
            circleID: circleID,
            title: title,
            author: author,
            pitch: pitch,
            lane: lane,
            stopMark: stopMark,
            endingClosed: endingClosed,
            suggestedBySeatID: suggestedBySeatID
        ) {
            QuillTap.confirm()
            dismiss()
        }
    }
}

enum QvMantlePloomSlipComposer474d6 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 18
        let tape = [16, 13, 14, 15]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-874-\(span % 15)")
    }
}
