import SwiftUI

struct GatheringComposerSheet: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let token: GatheringEditToken

    @State private var heldOn = Date()
    @State private var place = ""
    @State private var marks: [BrindleAgendaMark] = [BrindleAgendaMark(id: UUID(), line: "", done: false)]
    @State private var linkedSlipID: UUID?
    @State private var placeFault: String?
    @State private var agendaFault: String?
    @State private var loaded = false
    @State private var confirmDiscard = false
    @State private var baseline = ""

    private var slips: [PloomTitleSlip] {
        guard let circleID = vault.activeCircleID else { return [] }
        return vault.slips(for: circleID)
    }

    private var snapshot: String {
        let markText = marks.map { "\($0.id.uuidString)|\($0.line)|\($0.done)" }.joined(separator: ";")
        return "\(heldOn.timeIntervalSince1970)|\(place)|\(markText)|\(linkedSlipID?.uuidString ?? "")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("When")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    DatePicker("When", selection: $heldOn, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    QuillLineField(caption: "Place", text: $place, fault: placeFault)
                    Text("Agenda")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    ForEach(marks) { mark in
                        HStack(alignment: .center, spacing: 8) {
                            TextField("Agenda point", text: line(for: mark.id))
                                .font(.system(size: 16, design: .serif))
                                .padding(12)
                                .background(Color.brindleCard.opacity(0.92))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            if marks.count > 1 {
                                Button {
                                    marks.removeAll { $0.id == mark.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                                .accessibilityLabel("Remove agenda point")
                            }
                        }
                    }
                    Button("Add point") {
                        marks.append(BrindleAgendaMark(id: UUID(), line: "", done: false))
                    }
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                    .frame(minHeight: 44)
                    if let agendaFault {
                        Text(agendaFault)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.red)
                            .lineLimit(nil)
                    }
                    Text("Title to discuss")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    if slips.isEmpty {
                        Text("Add a title on the shelf if you want to attach one.")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    } else {
                        ForEach(slips) { slip in
                            Button {
                                linkedSlipID = linkedSlipID == slip.id ? nil : slip.id
                            } label: {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(slip.title)
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(nil)
                                        Text(slip.readingLane.folioLabel)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                    Spacer(minLength: 8)
                                    if linkedSlipID == slip.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    QuillPrimaryButton(title: "Save gathering") { commit() }
                    QuillQuietButton(title: "Cancel") { requestClose() }
                }
                .padding(16)
            }
            .quillKeyboardDone()
            .navigationTitle(token.existingID == nil ? "New gathering" : "Edit gathering")
            .navigationBarTitleDisplayMode(.inline)
            .quillLaidPaper()
            .onAppear(perform: load)
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("This gathering will stay as it was.")
            }
        }
        .interactiveDismissDisabled(loaded && snapshot != baseline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func line(for id: UUID) -> Binding<String> {
        Binding(
            get: { marks.first { $0.id == id }?.line ?? "" },
            set: { newValue in
                guard let index = marks.firstIndex(where: { $0.id == id }) else { return }
                marks[index].line = newValue
            }
        )
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let existingID = token.existingID, let item = vault.gathering(id: existingID) {
            heldOn = item.heldOn
            place = item.placeLabel
            linkedSlipID = item.linkedSlipID
            if item.agendaMarks.isEmpty {
                let lines = BrindleFieldCheck.lines(from: item.agendaNote)
                marks = lines.isEmpty
                    ? [BrindleAgendaMark(id: UUID(), line: "", done: false)]
                    : lines.map { BrindleAgendaMark(id: UUID(), line: $0, done: false) }
            } else {
                marks = item.agendaMarks
            }
        } else {
            heldOn = token.presetHeldOn ?? Date()
            place = token.presetPlace ?? vault.activeCircle?.placeHint ?? ""
            linkedSlipID = token.presetSlipID
            marks = token.presetMarks.isEmpty
                ? [BrindleAgendaMark(id: UUID(), line: "", done: false)]
                : token.presetMarks
        }
        baseline = snapshot
    }

    private func requestClose() {
        if snapshot != baseline { confirmDiscard = true } else { dismiss() }
    }

    private func commit() {
        placeFault = BrindleFieldCheck.required(place, hint: "Add a place so people know where to meet.")
        let filled = marks.contains { !BrindleFieldCheck.trimmed($0.line).isEmpty }
        agendaFault = filled ? nil : "Add at least one agenda point."
        guard placeFault == nil, agendaFault == nil, let circleID = vault.activeCircleID else { return }
        if vault.saveGathering(
            existingID: token.existingID,
            circleID: circleID,
            heldOn: heldOn,
            place: place,
            marks: marks,
            linkedSlipID: linkedSlipID
        ) {
            QuillTap.confirm()
            dismiss()
        }
    }
}

enum QvMantleGatheringComposerSheetde440 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 3
        let tape = [14, 18, 19, 4]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-805-\(span % 16)")
    }
}
