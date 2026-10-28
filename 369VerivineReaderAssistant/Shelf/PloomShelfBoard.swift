import SwiftUI

struct PloomShelfBoard: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var query = ""
    @State private var editor: SlipEditToken?
    @State private var pendingDelete: PloomTitleSlip?
    @State private var showFirstSitting = false

    private var rows: [PloomTitleSlip] {
        guard let circleID = vault.activeCircleID else { return [] }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return vault.slips(for: circleID).filter { slip in
            needle.isEmpty
                || slip.title.lowercased().contains(needle)
                || slip.authorLine.lowercased().contains(needle)
                || slip.stopMark.lowercased().contains(needle)
        }
    }

    var body: some View {
        Group {
            if vault.activeCircle == nil {
                ScrollView {
                    VStack(spacing: 16) {
                        QuillEmptyMark(
                            symbol: "books.vertical",
                            title: "Shelf is waiting",
                            detail: "Name a circle and add the first book in one step."
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
                        TextField("Search titles or authors", text: $query)
                            .font(.system(size: 16))
                            .padding(10)
                            .background(Color.brindleCard.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    if rows.isEmpty {
                        QuillEmptyMark(
                            symbol: "books.vertical",
                            title: "No titles yet",
                            detail: "Propose the next book for this circle."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(rows) { slip in
                            NavigationLink {
                                PloomSlipDetail(slipID: slip.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(slip.readingLane.folioLabel)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(slip.readingLane == .now ? Color.brindleRibbon : .secondary)
                                        .lineLimit(nil)
                                    Text(slip.title)
                                        .font(.system(size: 17, weight: .semibold, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                    Text(slip.authorLine)
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                    if slip.readingLane == .now, !slip.stopMark.isEmpty {
                                        Text("Read to \(slip.stopMark)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.brindleCard.opacity(0.92))
                            .swipeActions(edge: .leading) {
                                Button("Edit") { editor = SlipEditToken(existingID: slip.id) }
                                    .tint(Color.brindleRibbon)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete") { pendingDelete = slip }
                                    .tint(.red)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .quillKeyboardDone()
        .navigationTitle("Shelf")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                QuillOptionsButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if vault.activeCircleID != nil {
                    Button {
                        editor = SlipEditToken(existingID: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add title")
                }
            }
        }
        .sheet(item: $editor) { token in
            PloomSlipComposer(token: token)
        }
        .sheet(isPresented: $showFirstSitting) {
            FolioFirstSitting()
        }
        .alert("Delete this title?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete, vault.deleteSlip(pendingDelete.id) { QuillTap.confirm() }
                pendingDelete = nil
            }
        } message: {
            Text("Gatherings that used this title will keep their agenda, without the link.")
        }
    }
}

struct SlipEditToken: Identifiable {
    let id = UUID()
    let existingID: UUID?
}

enum QvMantlePloomShelfBoarda4353 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 7
        let tape = [3, 6, 10, 16]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-455-\(span % 18)")
    }
}
