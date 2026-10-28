import SwiftUI

struct CircleCradleBoard: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var editor: CircleEditToken?
    @State private var pendingDelete: BrindleCircleCard?
    @State private var showFirstSitting = false

    var body: some View {
        Group {
            if vault.circles.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        QuillEmptyMark(
                            symbol: "person.2",
                            title: "Create a circle",
                            detail: "Name the circle, add the first book, and set the first gathering."
                        )
                        QuillPrimaryButton(title: "Start a circle", identifier: "folio.startSitting") {
                            showFirstSitting = true
                        }
                    }
                    .padding(16)
                }
            } else {
                List {
                    Section {
                        QuillPrimaryButton(title: "New circle") {
                            editor = CircleEditToken(existingID: nil)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    ForEach(vault.circles) { circle in
                        QuillPaperCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(circle.title)
                                            .font(.system(size: 18, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        if !circle.placeHint.isEmpty {
                                            Text(circle.placeHint)
                                                .font(.system(size: 14, design: .serif))
                                                .foregroundColor(.secondary)
                                                .lineLimit(nil)
                                        }
                                        if let host = circle.hostName {
                                            HStack(spacing: 8) {
                                                Text("Host · \(host)")
                                                    .font(.system(size: 14, weight: .semibold, design: .serif))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(nil)
                                                if circle.seats.count > 1 {
                                                    Button("Next host") {
                                                        if vault.advanceHost(circle.id) { QuillTap.confirm() }
                                                    }
                                                    .buttonStyle(.borderless)
                                                    .font(.system(size: 14, weight: .semibold, design: .serif))
                                                }
                                            }
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    if vault.activeCircleID == circle.id {
                                        Text("Active")
                                            .font(.system(size: 12, weight: .bold, design: .serif))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Color.brindleInk))
                                    }
                                }
                                HStack(spacing: 8) {
                                    Button("Use this circle") { vault.selectCircle(circle.id) }
                                        .buttonStyle(.borderless)
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                    Button("Edit") { editor = CircleEditToken(existingID: circle.id) }
                                        .buttonStyle(.borderless)
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                    Button("Delete") { pendingDelete = circle }
                                        .buttonStyle(.borderless)
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button("Delete") { pendingDelete = circle }
                                .tint(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Circles")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .sheet(item: $editor) { token in
            CircleEditorSheet(token: token)
        }
        .sheet(isPresented: $showFirstSitting) {
            FolioFirstSitting()
        }
        .alert("Delete this circle?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    if vault.deleteCircle(pendingDelete.id) { QuillTap.confirm() }
                }
                pendingDelete = nil
            }
        } message: {
            Text("Gatherings, titles, and notes for this circle will be removed from this device.")
        }
    }
}

struct CircleEditToken: Identifiable {
    let id = UUID()
    let existingID: UUID?
}

struct CircleEditorSheet: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    let token: CircleEditToken
    @State private var title = ""
    @State private var place = ""
    @State private var seats: [BrindleSeat] = []
    @State private var hostSeatID: UUID?
    @State private var personDraft = ""
    @State private var titleFault: String?
    @State private var loaded = false
    @State private var confirmDiscard = false

    private var isDirty: Bool {
        guard loaded else { return false }
        if !BrindleFieldCheck.trimmed(personDraft).isEmpty { return true }
        if let existingID = token.existingID, let circle = vault.circle(id: existingID) {
            return title != circle.title
                || place != circle.placeHint
                || seats != circle.seats
                || hostSeatID != circle.hostSeatID
        }
        return !title.isEmpty || !place.isEmpty || !seats.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    QuillLineField(caption: "Circle name", text: $title, fault: titleFault)
                    QuillLineField(caption: "Usual place", text: $place, fault: nil)
                    Text("People")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        TextField("Name", text: $personDraft)
                            .font(.system(size: 16, design: .serif))
                            .padding(12)
                            .background(Color.brindleCard.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Button("Add") { addPerson() }
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .frame(minWidth: 64, minHeight: 44)
                    }
                    ForEach(seats) { seat in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(seat.name)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                            if hostSeatID == seat.id {
                                Text("Host")
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                            }
                            Spacer(minLength: 8)
                            if hostSeatID != seat.id {
                                Button("Set as host") { hostSeatID = seat.id }
                                    .font(.system(size: 14, weight: .semibold, design: .serif))
                                    .buttonStyle(.borderless)
                            }
                            Button("Remove") { removePerson(seat.id) }
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                                .foregroundColor(.red)
                                .buttonStyle(.borderless)
                        }
                        .frame(minHeight: 44)
                    }
                    Text("The host is whose turn it is to welcome the circle. Next host moves that turn along the list.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    QuillPrimaryButton(title: "Save circle") { commit() }
                    QuillQuietButton(title: "Cancel") { requestClose() }
                }
                .padding(16)
            }
            .quillKeyboardDone()
            .navigationTitle(token.existingID == nil ? "New circle" : "Edit circle")
            .navigationBarTitleDisplayMode(.inline)
            .quillLaidPaper()
            .onAppear(perform: load)
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("The name, place, and people you typed will not be stored.")
            }
        }
        .interactiveDismissDisabled(isDirty)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let existingID = token.existingID, let circle = vault.circle(id: existingID) {
            title = circle.title
            place = circle.placeHint
            seats = circle.seats
            hostSeatID = circle.hostSeatID
        }
    }

    private func addPerson() {
        let name = BrindleFieldCheck.trimmed(personDraft)
        guard !name.isEmpty else { return }
        let seat = BrindleSeat(id: UUID(), name: name)
        seats.append(seat)
        if hostSeatID == nil { hostSeatID = seat.id }
        personDraft = ""
    }

    private func removePerson(_ id: UUID) {
        seats.removeAll { $0.id == id }
        if hostSeatID == id { hostSeatID = seats.first?.id }
    }

    private func requestClose() {
        if isDirty { confirmDiscard = true } else { dismiss() }
    }

    private func commit() {
        titleFault = BrindleFieldCheck.required(title, hint: "Add a name for the circle.")
        guard titleFault == nil else { return }
        if vault.saveCircle(
            existingID: token.existingID,
            title: title,
            placeHint: place,
            seats: seats,
            hostSeatID: hostSeatID
        ) {
            QuillTap.confirm()
            dismiss()
        }
    }
}

struct FolioFirstSitting: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @Environment(\.dismiss) private var dismiss
    @State private var circleTitle = ""
    @State private var place = ""
    @State private var book = ""
    @State private var author = ""
    @State private var heldOn = FolioFirstSitting.suggestedDate
    @State private var baselineHeld = FolioFirstSitting.suggestedDate
    @State private var circleFault: String?
    @State private var placeFault: String?
    @State private var bookFault: String?
    @State private var authorFault: String?
    @State private var confirmDiscard = false

    private static var suggestedDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }

    private var isDirty: Bool {
        !BrindleFieldCheck.trimmed(circleTitle).isEmpty
            || !BrindleFieldCheck.trimmed(place).isEmpty
            || !BrindleFieldCheck.trimmed(book).isEmpty
            || !BrindleFieldCheck.trimmed(author).isEmpty
            || abs(heldOn.timeIntervalSince(baselineHeld)) > 30
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    QuillLineField(caption: "Circle name", text: $circleTitle, fault: circleFault)
                    QuillLineField(caption: "Usual place", text: $place, fault: placeFault)
                    QuillLineField(caption: "Book title", text: $book, fault: bookFault)
                    QuillLineField(caption: "Author", text: $author, fault: authorFault)
                    Text("When")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.secondary)
                    DatePicker("When", selection: $heldOn, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("This becomes the circle, the book you are reading now, and the first gathering.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    QuillPrimaryButton(title: "Create circle", identifier: "folio.createSitting") { commit() }
                    QuillQuietButton(title: "Cancel") { requestClose() }
                }
                .padding(16)
            }
            .quillKeyboardDone()
            .navigationTitle("First sitting")
            .navigationBarTitleDisplayMode(.inline)
            .quillLaidPaper()
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("This circle will not be created.")
            }
        }
        .interactiveDismissDisabled(isDirty)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { QuillBackdrop() }
    }

    private func requestClose() {
        if isDirty { confirmDiscard = true } else { dismiss() }
    }

    private func commit() {
        circleFault = BrindleFieldCheck.required(circleTitle, hint: "Add a name for the circle.")
        placeFault = BrindleFieldCheck.required(place, hint: "Add a place so people know where to meet.")
        bookFault = BrindleFieldCheck.required(book, hint: "Add the title.")
        authorFault = BrindleFieldCheck.required(author, hint: "Add the author.")
        guard circleFault == nil, placeFault == nil, bookFault == nil, authorFault == nil else { return }
        if vault.plantFirstSitting(
            circleTitle: circleTitle,
            place: place,
            bookTitle: book,
            author: author,
            heldOn: heldOn
        ) {
            QuillTap.confirm()
            dismiss()
        }
    }
}

enum QvMantleCircleCradleBoarde44cf {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 18
        let tape = [16, 14, 3, 18]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-688-\(span % 14)")
    }
}
