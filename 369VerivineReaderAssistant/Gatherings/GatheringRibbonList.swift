import SwiftUI

struct GatheringRibbonList: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var filter = 0
    @State private var query = ""
    @State private var monthAnchor = Date()
    @State private var pickedDay: Date?
    @State private var editor: GatheringEditToken?
    @State private var pendingDelete: BrindleGatheringSlip?
    @State private var showFirstSitting = false
    @State private var didAlignMonth = false

    private func alignMonthToNextGathering() {
        guard !didAlignMonth, let circleID = vault.activeCircleID else { return }
        guard let next = vault.gatherings(for: circleID).filter({ $0.heldOn >= Date() }).min(by: { $0.heldOn < $1.heldOn }) else { return }
        monthAnchor = next.heldOn
        didAlignMonth = true
    }

    private var meetingDays: Set<Date> {
        guard let circleID = vault.activeCircleID else { return [] }
        return Set(vault.gatherings(for: circleID).map { Calendar.current.startOfDay(for: $0.heldOn) })
    }

    private var rows: [BrindleGatheringSlip] {
        guard let circleID = vault.activeCircleID else { return [] }
        var items = vault.gatherings(for: circleID)
        if filter == 1 { items = items.filter { $0.heldOn >= Date() } }
        if filter == 2 { items = items.filter { $0.heldOn < Date() } }
        if let pickedDay {
            items = items.filter { Calendar.current.isDate($0.heldOn, inSameDayAs: pickedDay) }
        }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            items = items.filter { item in
                item.placeLabel.lowercased().contains(needle)
                    || item.agendaNote.lowercased().contains(needle)
                    || item.verdictLine.lowercased().contains(needle)
                    || item.agendaMarks.contains { $0.line.lowercased().contains(needle) }
            }
        }
        let upcoming = items.filter { $0.heldOn >= Date() }.sorted { $0.heldOn < $1.heldOn }
        let past = items.filter { $0.heldOn < Date() }.sorted { $0.heldOn > $1.heldOn }
        return upcoming + past
    }

    var body: some View {
        Group {
            if vault.activeCircle == nil {
                ScrollView {
                    VStack(spacing: 16) {
                        QuillEmptyMark(
                            symbol: "calendar.badge.plus",
                            title: "No Meetings Scheduled",
                            detail: "Name a circle, choose the first book, and set a date."
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
                        NavigationLink {
                            CircleCradleBoard()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active circle")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(vault.activeCircle?.title ?? "")
                                    .font(.system(size: 18, weight: .semibold, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                if let host = vault.activeCircle?.hostName {
                                    Text("Host · \(host)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.brindleRibbon)
                                        .lineLimit(nil)
                                }
                            }
                        }
                        .listRowBackground(Color.brindleCard.opacity(0.9))
                        Picker("Show", selection: $filter) {
                            Text("All").tag(0)
                            Text("Upcoming").tag(1)
                            Text("Past").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        TextField("Search place, agenda, or verdict", text: $query)
                            .font(.system(size: 16))
                            .padding(10)
                            .background(Color.brindleCard.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    if rows.isEmpty {
                        QuillEmptyMark(
                            symbol: "calendar.badge.plus",
                            title: pickedDay == nil ? "No Meetings Scheduled" : "Nothing on this day",
                            detail: pickedDay == nil
                                ? "Use the plus button to set a date, place, and agenda."
                                : "Pick another day, or show every day."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(rows) { item in
                            NavigationLink {
                                GatheringDetailLeaf(gatheringID: item.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.heldOn >= Date() ? "Upcoming" : "Past")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(item.heldOn >= Date() ? Color.brindleRibbon : .secondary)
                                    Text(QuillDateInk.medium(item.heldOn))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                    Text(item.placeLabel)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                    if !item.agendaMarks.isEmpty {
                                        let done = item.agendaMarks.filter(\.done).count
                                        Text("\(done) of \(item.agendaMarks.count) agenda points")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                    if let slipID = item.linkedSlipID, let slip = vault.slip(id: slipID) {
                                        Text(slip.title)
                                            .font(.system(size: 14, design: .serif))
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.brindleCard.opacity(0.92))
                            .swipeActions(edge: .leading) {
                                Button("Edit") {
                                    editor = GatheringEditToken(existingID: item.id, presetSlipID: nil)
                                }
                                .tint(Color.brindleRibbon)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete") { pendingDelete = item }
                                    .tint(.red)
                            }
                        }
                    }
                    Section {
                        QuillMonthLattice(anchor: $monthAnchor, pickedDay: $pickedDay, meetingDays: meetingDays)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        if pickedDay != nil {
                            Button("Show every day") { pickedDay = nil }
                                .buttonStyle(.borderless)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.brindleRibbon)
                                .frame(minHeight: 44)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .onAppear(perform: alignMonthToNextGathering)
            }
        }
        .quillKeyboardDone()
        .navigationTitle("Gatherings")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                QuillOptionsButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if vault.activeCircleID != nil {
                    Button {
                        editor = GatheringEditToken(existingID: nil, presetSlipID: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add gathering")
                }
            }
        }
        .sheet(item: $editor) { token in
            GatheringComposerSheet(token: token)
        }
        .sheet(isPresented: $showFirstSitting) {
            FolioFirstSitting()
        }
        .alert("Delete this gathering?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    if vault.deleteGathering(pendingDelete.id) { QuillTap.confirm() }
                }
                pendingDelete = nil
            }
        } message: {
            Text("The agenda and any notes tied to this gathering will be removed.")
        }
    }
}

struct GatheringEditToken: Identifiable {
    let id = UUID()
    let existingID: UUID?
    let presetSlipID: UUID?
    var presetHeldOn: Date?
    var presetPlace: String?
    var presetMarks: [BrindleAgendaMark] = []
}

struct QuillMonthLattice: View {
    @Binding var anchor: Date
    @Binding var pickedDay: Date?
    let meetingDays: Set<Date>

    private var calendar: Calendar { Calendar.current }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)) ?? anchor
    }

    private var weekdayLabels: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        guard symbols.count == 7, (0..<7).contains(start) else { return symbols }
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private var cells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        for day in range {
            result.append(calendar.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        while result.count % 7 != 0 {
            result.append(nil)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    anchor = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? anchor
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous month")
                Spacer(minLength: 8)
                Text(QuillDateInk.monthTitle(monthStart))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                Spacer(minLength: 8)
                Button {
                    anchor = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? anchor
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Next month")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let selected = pickedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let marked = meetingDays.contains(calendar.startOfDay(for: day))
        return Button {
            pickedDay = selected ? nil : day
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? .black : .primary)
                Circle()
                    .fill(marked ? Color.brindleRibbon : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Color.brindleInk : Color.clear)
            )
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(day, style: .date))
    }
}

enum QvMantleGatheringRibbonListb510c {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 3
        let tape = [16, 3, 5, 13]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 1)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-302-\(span % 15)")
    }
}
