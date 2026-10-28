import Combine
import Foundation
import UserNotifications

@MainActor
final class BrindleCircleVault: ObservableObject {
    @Published var hasSeenFolioIntro: Bool
    @Published var circles: [BrindleCircleCard]
    @Published var gatherings: [BrindleGatheringSlip]
    @Published var slips: [PloomTitleSlip]
    @Published var leaves: [NexilMarginLeaf]
    @Published var activeCircleID: UUID?
    @Published var saveFault: String?
    @Published var toastLine: String?

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.decoder = decoder
        hasSeenFolioIntro = defaults.bool(forKey: BrindleVaultKey.seenIntro)
        circles = Self.load(BrindleCircleCard.self, key: BrindleVaultKey.circles, defaults: defaults, decoder: decoder)
        gatherings = Self.load(BrindleGatheringSlip.self, key: BrindleVaultKey.gatherings, defaults: defaults, decoder: decoder)
        slips = Self.load(PloomTitleSlip.self, key: BrindleVaultKey.slips, defaults: defaults, decoder: decoder)
        leaves = Self.load(NexilMarginLeaf.self, key: BrindleVaultKey.leaves, defaults: defaults, decoder: decoder)
        if let raw = defaults.string(forKey: BrindleVaultKey.activeCircle),
           let id = UUID(uuidString: raw),
           circles.contains(where: { $0.id == id }) {
            activeCircleID = id
        } else {
            activeCircleID = circles.first?.id
        }
        if normalizeStoredShape() {
            _ = persistAll()
        }
        syncReminders(ask: false)
    }

    var activeCircle: BrindleCircleCard? {
        circles.first { $0.id == activeCircleID }
    }

    func gatherings(for circleID: UUID) -> [BrindleGatheringSlip] {
        gatherings.filter { $0.circleID == circleID }
    }

    func slips(for circleID: UUID) -> [PloomTitleSlip] {
        slips.filter { $0.circleID == circleID }.sorted { $0.createdAt > $1.createdAt }
    }

    func leaves(for gatheringID: UUID) -> [NexilMarginLeaf] {
        leaves.filter { $0.gatheringID == gatheringID }.sorted { $0.savedAt > $1.savedAt }
    }

    func circle(id: UUID) -> BrindleCircleCard? {
        circles.first { $0.id == id }
    }

    func gathering(id: UUID) -> BrindleGatheringSlip? {
        gatherings.first { $0.id == id }
    }

    func slip(id: UUID) -> PloomTitleSlip? {
        slips.first { $0.id == id }
    }

    func leaf(id: UUID) -> NexilMarginLeaf? {
        leaves.first { $0.id == id }
    }

    func seatName(_ id: UUID?) -> String? {
        guard let id else { return nil }
        for circle in circles {
            if let seat = circle.seats.first(where: { $0.id == id }) {
                return seat.name
            }
        }
        return nil
    }

    func currentSlip(in circleID: UUID) -> PloomTitleSlip? {
        slips.first { $0.circleID == circleID && $0.readingLane == .now }
    }

    func markIntroSeen() {
        hasSeenFolioIntro = true
        defaults.set(true, forKey: BrindleVaultKey.seenIntro)
    }

    @discardableResult
    func saveCircle(
        existingID: UUID?,
        title: String,
        placeHint: String,
        seats: [BrindleSeat],
        hostSeatID: UUID?
    ) -> Bool {
        let cleanTitle = BrindleFieldCheck.trimmed(title)
        let cleanPlace = BrindleFieldCheck.trimmed(placeHint)
        guard !cleanTitle.isEmpty else { return false }
        let cleanSeats = seats.compactMap { seat -> BrindleSeat? in
            let name = BrindleFieldCheck.trimmed(seat.name)
            guard !name.isEmpty else { return nil }
            return BrindleSeat(id: seat.id, name: name)
        }
        let host = cleanSeats.contains(where: { $0.id == hostSeatID }) ? hostSeatID : cleanSeats.first?.id
        return mutate(toast: "Circle saved.") {
            if let existingID, let index = circles.firstIndex(where: { $0.id == existingID }) {
                circles[index].title = cleanTitle
                circles[index].placeHint = cleanPlace
                circles[index].seats = cleanSeats
                circles[index].hostSeatID = host
                let seatIDs = Set(cleanSeats.map(\.id))
                for slipIndex in slips.indices where slips[slipIndex].circleID == existingID {
                    if let suggested = slips[slipIndex].suggestedBySeatID, !seatIDs.contains(suggested) {
                        slips[slipIndex].suggestedBySeatID = nil
                    }
                }
            } else {
                let card = BrindleCircleCard(
                    id: UUID(),
                    title: cleanTitle,
                    placeHint: cleanPlace,
                    createdAt: Date(),
                    seats: cleanSeats,
                    hostSeatID: host
                )
                circles.append(card)
                activeCircleID = card.id
            }
        }
    }

    @discardableResult
    func advanceHost(_ circleID: UUID) -> Bool {
        guard let circle = circle(id: circleID), circle.seats.count > 1 else { return false }
        let seats = circle.seats
        let next: UUID
        if let host = circle.hostSeatID, let current = seats.firstIndex(where: { $0.id == host }) {
            next = seats[(current + 1) % seats.count].id
        } else {
            next = seats[0].id
        }
        return mutate(toast: "Host updated.") {
            guard let index = circles.firstIndex(where: { $0.id == circleID }) else { return }
            circles[index].hostSeatID = next
        }
    }

    func selectCircle(_ id: UUID) {
        guard circles.contains(where: { $0.id == id }) else { return }
        activeCircleID = id
        _ = persistAll()
    }

    @discardableResult
    func deleteCircle(_ id: UUID) -> Bool {
        mutate(toast: "Circle removed.") {
            let gatheringIDs = Set(gatherings.filter { $0.circleID == id }.map(\.id))
            leaves.removeAll { gatheringIDs.contains($0.gatheringID) }
            gatherings.removeAll { $0.circleID == id }
            slips.removeAll { $0.circleID == id }
            circles.removeAll { $0.id == id }
            if activeCircleID == id {
                activeCircleID = circles.first?.id
            }
        }
    }

    @discardableResult
    func plantFirstSitting(
        circleTitle: String,
        place: String,
        bookTitle: String,
        author: String,
        heldOn: Date
    ) -> Bool {
        let cleanCircle = BrindleFieldCheck.trimmed(circleTitle)
        let cleanPlace = BrindleFieldCheck.trimmed(place)
        let cleanBook = BrindleFieldCheck.trimmed(bookTitle)
        let cleanAuthor = BrindleFieldCheck.trimmed(author)
        guard !cleanCircle.isEmpty, !cleanPlace.isEmpty, !cleanBook.isEmpty, !cleanAuthor.isEmpty else { return false }
        return mutate(toast: "Circle saved.", askReminder: true) {
            let circleID = UUID()
            circles.append(BrindleCircleCard(
                id: circleID,
                title: cleanCircle,
                placeHint: cleanPlace,
                createdAt: Date()
            ))
            activeCircleID = circleID
            let slipID = UUID()
            slips.append(PloomTitleSlip(
                id: slipID,
                circleID: circleID,
                title: cleanBook,
                authorLine: cleanAuthor,
                pitchNote: "",
                chosen: true,
                createdAt: Date(),
                readingLane: .now
            ))
            let mark = BrindleAgendaMark(id: UUID(), line: "Discuss the book", done: false)
            gatherings.append(BrindleGatheringSlip(
                id: UUID(),
                circleID: circleID,
                heldOn: heldOn,
                placeLabel: cleanPlace,
                agendaNote: mark.line,
                linkedSlipID: slipID,
                agendaMarks: [mark]
            ))
            refreshChosenFlags()
        }
    }

    @discardableResult
    func saveGathering(
        existingID: UUID?,
        circleID: UUID,
        heldOn: Date,
        place: String,
        marks: [BrindleAgendaMark],
        linkedSlipID: UUID?
    ) -> Bool {
        let cleanPlace = BrindleFieldCheck.trimmed(place)
        let cleanMarks = marks.compactMap { mark -> BrindleAgendaMark? in
            let line = BrindleFieldCheck.trimmed(mark.line)
            guard !line.isEmpty else { return nil }
            return BrindleAgendaMark(id: mark.id, line: line, done: mark.done)
        }
        guard !cleanPlace.isEmpty, !cleanMarks.isEmpty else { return false }
        guard circles.contains(where: { $0.id == circleID }) else { return false }
        let linked = linkedSlipID.flatMap { slipID in slips.contains(where: { $0.id == slipID }) ? slipID : nil }
        return mutate(toast: "Gathering saved.", askReminder: true) {
            let note = cleanMarks.map(\.line).joined(separator: "\n")
            if let existingID, let index = gatherings.firstIndex(where: { $0.id == existingID }) {
                gatherings[index].heldOn = heldOn
                gatherings[index].placeLabel = cleanPlace
                gatherings[index].agendaNote = note
                gatherings[index].agendaMarks = cleanMarks
                gatherings[index].linkedSlipID = linked
            } else {
                gatherings.append(BrindleGatheringSlip(
                    id: UUID(),
                    circleID: circleID,
                    heldOn: heldOn,
                    placeLabel: cleanPlace,
                    agendaNote: note,
                    linkedSlipID: linked,
                    agendaMarks: cleanMarks
                ))
            }
            refreshChosenFlags()
        }
    }

    @discardableResult
    func toggleAgendaMark(gatheringID: UUID, markID: UUID) -> Bool {
        guard gatherings.contains(where: { item in
            item.id == gatheringID && item.agendaMarks.contains(where: { $0.id == markID })
        }) else { return false }
        return mutate(toast: nil) {
            guard let gatheringIndex = gatherings.firstIndex(where: { $0.id == gatheringID }),
                  let markIndex = gatherings[gatheringIndex].agendaMarks.firstIndex(where: { $0.id == markID }) else { return }
            gatherings[gatheringIndex].agendaMarks[markIndex].done.toggle()
            gatherings[gatheringIndex].agendaNote = gatherings[gatheringIndex].agendaMarks.map(\.line).joined(separator: "\n")
        }
    }

    @discardableResult
    func saveVerdict(gatheringID: UUID, score: Int?, line: String, finishLinkedTitle: Bool) -> Bool {
        let cleanLine = BrindleFieldCheck.trimmed(line)
        let storedScore: Int?
        if let score, (1...5).contains(score) {
            storedScore = score
        } else {
            storedScore = nil
        }
        guard storedScore != nil || !cleanLine.isEmpty else { return false }
        guard gatherings.contains(where: { $0.id == gatheringID }) else { return false }
        return mutate(toast: "Verdict saved.") {
            guard let index = gatherings.firstIndex(where: { $0.id == gatheringID }) else { return }
            gatherings[index].clubScore = storedScore
            gatherings[index].verdictLine = cleanLine
            if finishLinkedTitle,
               let slipID = gatherings[index].linkedSlipID,
               let slipIndex = slips.firstIndex(where: { $0.id == slipID }) {
                slips[slipIndex].readingLane = .done
            }
        }
    }

    @discardableResult
    func deleteGathering(_ id: UUID) -> Bool {
        mutate(toast: "Gathering removed.") {
            gatherings.removeAll { $0.id == id }
            leaves.removeAll { $0.gatheringID == id }
            refreshChosenFlags()
        }
    }

    @discardableResult
    func saveSlip(
        existingID: UUID?,
        circleID: UUID,
        title: String,
        author: String,
        pitch: String,
        lane: PloomReadingLane,
        stopMark: String,
        endingClosed: Bool,
        suggestedBySeatID: UUID?
    ) -> Bool {
        let cleanTitle = BrindleFieldCheck.trimmed(title)
        let cleanAuthor = BrindleFieldCheck.trimmed(author)
        let cleanPitch = BrindleFieldCheck.trimmed(pitch)
        let cleanStop = BrindleFieldCheck.trimmed(stopMark)
        guard !cleanTitle.isEmpty, !cleanAuthor.isEmpty else { return false }
        guard circles.contains(where: { $0.id == circleID }) else { return false }
        let seatIDs = Set(circles.first { $0.id == circleID }?.seats.map(\.id) ?? [])
        let suggested = suggestedBySeatID.flatMap { seatIDs.contains($0) ? $0 : nil }
        return mutate(toast: "Title saved.") {
            if let existingID, let index = slips.firstIndex(where: { $0.id == existingID }) {
                slips[index].title = cleanTitle
                slips[index].authorLine = cleanAuthor
                slips[index].pitchNote = cleanPitch
                slips[index].stopMark = cleanStop
                slips[index].endingClosed = endingClosed
                slips[index].suggestedBySeatID = suggested
                applyLane(lane, at: index)
            } else {
                slips.append(PloomTitleSlip(
                    id: UUID(),
                    circleID: circleID,
                    title: cleanTitle,
                    authorLine: cleanAuthor,
                    pitchNote: cleanPitch,
                    chosen: false,
                    createdAt: Date(),
                    readingLane: .queue,
                    stopMark: cleanStop,
                    endingClosed: endingClosed,
                    suggestedBySeatID: suggested
                ))
                if let index = slips.indices.last {
                    applyLane(lane, at: index)
                }
            }
            refreshChosenFlags()
        }
    }

    @discardableResult
    func setReadingLane(_ slipID: UUID, lane: PloomReadingLane) -> Bool {
        guard let index = slips.firstIndex(where: { $0.id == slipID }) else { return false }
        if slips[index].readingLane == lane { return true }
        return mutate(toast: "Title updated.") {
            guard let index = slips.firstIndex(where: { $0.id == slipID }) else { return }
            applyLane(lane, at: index)
        }
    }

    @discardableResult
    func deleteSlip(_ id: UUID) -> Bool {
        mutate(toast: "Title removed.") {
            slips.removeAll { $0.id == id }
            for index in gatherings.indices where gatherings[index].linkedSlipID == id {
                gatherings[index].linkedSlipID = nil
            }
            refreshChosenFlags()
        }
    }

    @discardableResult
    func saveLeaf(
        existingID: UUID?,
        gatheringID: UUID,
        title: String,
        points: String,
        quote: String,
        page: String,
        reaction: String,
        spoilerChapter: String
    ) -> Bool {
        let cleanTitle = BrindleFieldCheck.trimmed(title)
        let cleanPoints = BrindleFieldCheck.trimmed(points)
        let cleanQuote = BrindleFieldCheck.trimmed(quote)
        let cleanPage = BrindleFieldCheck.trimmed(page)
        let cleanReaction = BrindleFieldCheck.trimmed(reaction)
        let cleanSpoiler = BrindleFieldCheck.trimmed(spoilerChapter)
        guard !cleanTitle.isEmpty else { return false }
        guard !cleanPoints.isEmpty || !cleanQuote.isEmpty || !cleanReaction.isEmpty else { return false }
        guard gatherings.contains(where: { $0.id == gatheringID }) else { return false }
        return mutate(toast: "Notes saved.") {
            if let existingID, let index = leaves.firstIndex(where: { $0.id == existingID }) {
                let previousSpoiler = BrindleFieldCheck.trimmed(leaves[index].spoilerChapter)
                leaves[index].gatheringID = gatheringID
                leaves[index].title = cleanTitle
                leaves[index].points = cleanPoints
                leaves[index].quoteLine = cleanQuote
                leaves[index].pageLabel = cleanPage
                leaves[index].reaction = cleanReaction
                leaves[index].spoilerChapter = cleanSpoiler
                leaves[index].savedAt = Date()
                if previousSpoiler != cleanSpoiler {
                    leaves[index].spoilerLifted = false
                }
            } else {
                leaves.append(NexilMarginLeaf(
                    id: UUID(),
                    gatheringID: gatheringID,
                    title: cleanTitle,
                    points: cleanPoints,
                    savedAt: Date(),
                    quoteLine: cleanQuote,
                    pageLabel: cleanPage,
                    reaction: cleanReaction,
                    spoilerChapter: cleanSpoiler
                ))
            }
        }
    }

    @discardableResult
    func liftSpoiler(_ id: UUID) -> Bool {
        guard let leaf = leaf(id: id), leaf.spoilerSealed else { return false }
        return mutate(toast: nil) {
            guard let index = leaves.firstIndex(where: { $0.id == id }) else { return }
            leaves[index].spoilerLifted = true
        }
    }

    @discardableResult
    func deleteLeaf(_ id: UUID) -> Bool {
        mutate(toast: "Note removed.") {
            leaves.removeAll { $0.id == id }
        }
    }

    func resetAll() {
        circles = []
        gatherings = []
        slips = []
        leaves = []
        activeCircleID = nil
        toastLine = "Stored entries were removed."
        saveFault = nil
        [
            BrindleVaultKey.circles,
            BrindleVaultKey.gatherings,
            BrindleVaultKey.slips,
            BrindleVaultKey.leaves,
            BrindleVaultKey.activeCircle
        ].forEach { defaults.removeObject(forKey: $0) }
        syncReminders(ask: false)
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    @discardableResult
    func persistAll() -> Bool {
        do {
            let circleData = try encoder.encode(circles)
            let gatheringData = try encoder.encode(gatherings)
            let slipData = try encoder.encode(slips)
            let leafData = try encoder.encode(leaves)
            defaults.set(circleData, forKey: BrindleVaultKey.circles)
            defaults.set(gatheringData, forKey: BrindleVaultKey.gatherings)
            defaults.set(slipData, forKey: BrindleVaultKey.slips)
            defaults.set(leafData, forKey: BrindleVaultKey.leaves)
            if let activeCircleID {
                defaults.set(activeCircleID.uuidString, forKey: BrindleVaultKey.activeCircle)
            } else {
                defaults.removeObject(forKey: BrindleVaultKey.activeCircle)
            }
            saveFault = nil
            return true
        } catch {
            saveFault = "The last change could not be stored. Free a little space, then try again."
            return false
        }
    }

    private func applyLane(_ lane: PloomReadingLane, at index: Int) {
        let circleID = slips[index].circleID
        let slipID = slips[index].id
        if lane == .now {
            for other in slips.indices where slips[other].circleID == circleID && slips[other].id != slipID && slips[other].readingLane == .now {
                slips[other].readingLane = .queue
            }
        }
        slips[index].readingLane = lane
    }

    private func refreshChosenFlags() {
        let linked = Set(gatherings.compactMap(\.linkedSlipID))
        for index in slips.indices {
            slips[index].chosen = linked.contains(slips[index].id)
        }
    }

    private func normalizeStoredShape() -> Bool {
        var changed = false
        for index in gatherings.indices where gatherings[index].agendaMarks.isEmpty {
            let lines = BrindleFieldCheck.lines(from: gatherings[index].agendaNote)
            if !lines.isEmpty {
                gatherings[index].agendaMarks = lines.map { BrindleAgendaMark(id: UUID(), line: $0, done: false) }
                changed = true
            }
        }
        for index in circles.indices {
            let ids = Set(circles[index].seats.map(\.id))
            if let host = circles[index].hostSeatID, !ids.contains(host) {
                circles[index].hostSeatID = circles[index].seats.first?.id
                changed = true
            }
        }
        let liveSeats = Set(circles.flatMap { $0.seats.map(\.id) })
        for index in slips.indices {
            if let suggested = slips[index].suggestedBySeatID, !liveSeats.contains(suggested) {
                slips[index].suggestedBySeatID = nil
                changed = true
            }
        }
        var keeper: [UUID: UUID] = [:]
        var keeperDate: [UUID: Date] = [:]
        for slip in slips where slip.readingLane == .now {
            if let existing = keeperDate[slip.circleID], slip.createdAt < existing {
                continue
            }
            keeperDate[slip.circleID] = slip.createdAt
            keeper[slip.circleID] = slip.id
        }
        for index in slips.indices where slips[index].readingLane == .now && keeper[slips[index].circleID] != slips[index].id {
            slips[index].readingLane = .queue
            changed = true
        }
        let linked = Set(gatherings.compactMap(\.linkedSlipID))
        for index in slips.indices {
            let flag = linked.contains(slips[index].id)
            if slips[index].chosen != flag {
                slips[index].chosen = flag
                changed = true
            }
        }
        return changed
    }

    private func syncReminders(ask: Bool) {
        let gatherings = gatherings
        let slips = slips
        Task {
            await QuillReminder.align(gatherings: gatherings, slips: slips, ask: ask)
        }
    }

    private func mutate(toast: String?, askReminder: Bool = false, _ body: () -> Void) -> Bool {
        let snap = Snapshot(
            circles: circles,
            gatherings: gatherings,
            slips: slips,
            leaves: leaves,
            active: activeCircleID
        )
        body()
        if persistAll() {
            if let toast {
                toastLine = toast
            }
            syncReminders(ask: askReminder)
            return true
        }
        circles = snap.circles
        gatherings = snap.gatherings
        slips = snap.slips
        leaves = snap.leaves
        activeCircleID = snap.active
        return false
    }

    private struct Snapshot {
        var circles: [BrindleCircleCard]
        var gatherings: [BrindleGatheringSlip]
        var slips: [PloomTitleSlip]
        var leaves: [NexilMarginLeaf]
        var active: UUID?
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults, decoder: JSONDecoder) -> [T] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([T].self, from: data)) ?? []
    }
}

enum QuillReminder {
    static func align(gatherings: [BrindleGatheringSlip], slips: [PloomTitleSlip], ask: Bool) async {
        let center = UNUserNotificationCenter.current()
        let known = Set(gatherings.map { $0.id.uuidString })
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { identifier in
            UUID(uuidString: identifier) != nil && !known.contains(identifier)
        }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }
        let settings = await center.notificationSettings()
        let allowed: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            allowed = true
        case .notDetermined:
            if ask {
                allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            } else {
                allowed = false
            }
        case .denied:
            allowed = false
        @unknown default:
            allowed = false
        }
        guard allowed else { return }
        for item in gatherings {
            let book = slips.first { $0.id == item.linkedSlipID }?.title
            await place(item, bookTitle: book, center: center)
        }
    }

    private static func place(
        _ gathering: BrindleGatheringSlip,
        bookTitle: String?,
        center: UNUserNotificationCenter
    ) async {
        let identifier = gathering.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let fire = fireDate(for: gathering.heldOn) else { return }
        let content = UNMutableNotificationContent()
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: gathering.heldOn)
        if let dayBefore, fire >= dayBefore.addingTimeInterval(-60) {
            content.title = "Gathering tomorrow"
        } else {
            content.title = "Gathering soon"
        }
        var body = "\(QuillDateInk.medium(gathering.heldOn)) · \(gathering.placeLabel)"
        if let bookTitle {
            let clean = BrindleFieldCheck.trimmed(bookTitle)
            if !clean.isEmpty {
                body += " · \(clean)"
            }
        }
        content.body = body
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func fireDate(for heldOn: Date) -> Date? {
        guard heldOn > Date() else { return nil }
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: heldOn), dayBefore > Date() {
            return dayBefore
        }
        let soon = heldOn.addingTimeInterval(-3600)
        return soon > Date() ? soon : nil
    }
}

enum QvMantleBrindleCircleVault55cbe {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 6
        let tape = [4, 10, 18, 19]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-195-\(span % 10)")
    }
}
