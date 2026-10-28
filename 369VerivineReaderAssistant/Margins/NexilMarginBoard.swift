import SwiftUI

struct NexilMarginBoard: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var query = ""
    @State private var editor: MarginEditToken?
    @State private var pendingDelete: NexilMarginLeaf?
    @State private var showFirstSitting = false

    private var allNotes: [NexilMarginLeaf] {
        guard let circleID = vault.activeCircleID else { return [] }
        let gatheringIDs = Set(vault.gatherings(for: circleID).map(\.id))
        return vault.leaves
            .filter { gatheringIDs.contains($0.gatheringID) }
            .sorted { $0.savedAt > $1.savedAt }
    }

    private var rows: [NexilMarginLeaf] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return allNotes }
        return allNotes.filter { note in
            [
                note.title,
                note.points,
                note.quoteLine,
                note.pageLabel,
                note.reaction,
                note.spoilerChapter
            ]
            .joined(separator: "\n")
            .lowercased()
            .contains(needle)
        }
    }

    var body: some View {
        Group {
            if vault.activeCircle == nil {
                ScrollView {
                    VStack(spacing: 16) {
                        QuillEmptyMark(
                            symbol: "book.closed",
                            title: "Notes need a circle",
                            detail: "Name a circle, choose a book, and set a gathering before you write."
                        )
                        QuillPrimaryButton(title: "Start a circle", identifier: "folio.startSitting") {
                            showFirstSitting = true
                        }
                    }
                    .padding(16)
                }
            } else if allNotes.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        QuillEmptyMark(
                            symbol: "book.closed",
                            title: "No discussion notes yet",
                            detail: "Open a gathering and write the first point, or add a note here."
                        )
                        if vault.gatherings(for: vault.activeCircleID ?? UUID()).isEmpty {
                            Text("Schedule a gathering before writing notes.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        } else {
                            QuillPrimaryButton(title: "New note") {
                                editor = MarginEditToken(existingID: nil, presetGatheringID: nil)
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                List {
                    Section {
                        TextField("Search notes", text: $query)
                            .font(.system(size: 16))
                            .padding(10)
                            .background(Color.brindleCard.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    if rows.isEmpty {
                        QuillEmptyMark(
                            symbol: "book.closed",
                            title: "No notes match",
                            detail: "Try another word from the quote, the page, or the discussion."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    ForEach(rows) { note in
                        noteBody(note)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.brindleCard.opacity(0.92))
                        .swipeActions {
                            Button("Delete") { pendingDelete = note }
                                .tint(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .quillKeyboardDone()
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                QuillOptionsButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let circleID = vault.activeCircleID, !vault.gatherings(for: circleID).isEmpty {
                    Button {
                        editor = MarginEditToken(existingID: nil, presetGatheringID: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add note")
                }
            }
        }
        .sheet(item: $editor) { token in
            NexilMarginEditor(token: token)
        }
        .sheet(isPresented: $showFirstSitting) {
            FolioFirstSitting()
        }
        .alert("Delete this note?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete, vault.deleteLeaf(pendingDelete.id) { QuillTap.confirm() }
                pendingDelete = nil
            }
        } message: {
            Text("The discussion points in this note will be removed from this device.")
        }
    }

    @ViewBuilder
    private func noteBody(_ note: NexilMarginLeaf) -> some View {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if note.spoilerSealed {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                Text("Closed until chapter \(note.spoilerChapter)")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                if !needle.isEmpty && !note.title.lowercased().contains(needle) {
                    Text("A match is inside this closed note.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                Button("Show note") {
                    if vault.liftSpoiler(note.id) { QuillTap.confirm() }
                }
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundColor(.primary)
                .frame(minHeight: 44)
                .buttonStyle(.borderless)
            }
        } else {
            Button {
                editor = MarginEditToken(existingID: note.id, presetGatheringID: note.gatheringID)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                    if let gathering = vault.gathering(id: note.gatheringID) {
                        Text(QuillDateInk.medium(gathering.heldOn))
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    if !note.pageLabel.isEmpty {
                        Text(note.pageLabel)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    Text(note.previewLine)
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct MarginEditToken: Identifiable {
    let id = UUID()
    let existingID: UUID?
    let presetGatheringID: UUID?
}

enum QvMantleNexilMarginBoard9d32f {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 18
        let tape = [13, 3, 15, 6]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-292-\(span % 11)")
    }
}
