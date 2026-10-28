import Foundation

enum PloomReadingLane: String, Codable, Equatable {
    case queue
    case now
    case done

    var folioLabel: String {
        switch self {
        case .queue: return "In the queue"
        case .now: return "Reading now"
        case .done: return "Finished"
        }
    }
}

struct BrindleSeat: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
}

struct BrindleAgendaMark: Codable, Identifiable, Equatable {
    var id: UUID
    var line: String
    var done: Bool
}

struct BrindleCircleCard: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var placeHint: String
    var createdAt: Date
    var seats: [BrindleSeat]
    var hostSeatID: UUID?

    var hostName: String? {
        guard let hostSeatID else { return nil }
        return seats.first { $0.id == hostSeatID }?.name
    }

    init(
        id: UUID,
        title: String,
        placeHint: String,
        createdAt: Date,
        seats: [BrindleSeat] = [],
        hostSeatID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.placeHint = placeHint
        self.createdAt = createdAt
        self.seats = seats
        self.hostSeatID = hostSeatID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        placeHint = container.soft(.placeHint, "")
        createdAt = container.soft(.createdAt, Date())
        seats = container.soft(.seats, [])
        hostSeatID = container.soft(.hostSeatID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(placeHint, forKey: .placeHint)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(seats, forKey: .seats)
        try container.encodeIfPresent(hostSeatID, forKey: .hostSeatID)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, placeHint, createdAt, seats, hostSeatID
    }
}

struct BrindleGatheringSlip: Codable, Identifiable, Equatable {
    var id: UUID
    var circleID: UUID
    var heldOn: Date
    var placeLabel: String
    var agendaNote: String
    var linkedSlipID: UUID?
    var agendaMarks: [BrindleAgendaMark]
    var clubScore: Int?
    var verdictLine: String

    init(
        id: UUID,
        circleID: UUID,
        heldOn: Date,
        placeLabel: String,
        agendaNote: String,
        linkedSlipID: UUID?,
        agendaMarks: [BrindleAgendaMark] = [],
        clubScore: Int? = nil,
        verdictLine: String = ""
    ) {
        self.id = id
        self.circleID = circleID
        self.heldOn = heldOn
        self.placeLabel = placeLabel
        self.agendaNote = agendaNote
        self.linkedSlipID = linkedSlipID
        self.agendaMarks = agendaMarks
        self.clubScore = clubScore
        self.verdictLine = verdictLine
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        circleID = try container.decode(UUID.self, forKey: .circleID)
        heldOn = try container.decode(Date.self, forKey: .heldOn)
        placeLabel = container.soft(.placeLabel, "")
        agendaNote = container.soft(.agendaNote, "")
        linkedSlipID = container.soft(.linkedSlipID)
        agendaMarks = container.soft(.agendaMarks, [])
        let score = container.soft(.clubScore, 0)
        clubScore = (1...5).contains(score) ? score : nil
        verdictLine = container.soft(.verdictLine, "")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(circleID, forKey: .circleID)
        try container.encode(heldOn, forKey: .heldOn)
        try container.encode(placeLabel, forKey: .placeLabel)
        try container.encode(agendaNote, forKey: .agendaNote)
        try container.encodeIfPresent(linkedSlipID, forKey: .linkedSlipID)
        try container.encode(agendaMarks, forKey: .agendaMarks)
        try container.encodeIfPresent(clubScore, forKey: .clubScore)
        try container.encode(verdictLine, forKey: .verdictLine)
    }

    private enum CodingKeys: String, CodingKey {
        case id, circleID, heldOn, placeLabel, agendaNote, linkedSlipID, agendaMarks, clubScore, verdictLine
    }
}

struct PloomTitleSlip: Codable, Identifiable, Equatable {
    var id: UUID
    var circleID: UUID
    var title: String
    var authorLine: String
    var pitchNote: String
    var chosen: Bool
    var createdAt: Date
    var readingLane: PloomReadingLane
    var stopMark: String
    var endingClosed: Bool
    var suggestedBySeatID: UUID?

    init(
        id: UUID,
        circleID: UUID,
        title: String,
        authorLine: String,
        pitchNote: String,
        chosen: Bool,
        createdAt: Date,
        readingLane: PloomReadingLane = .queue,
        stopMark: String = "",
        endingClosed: Bool = false,
        suggestedBySeatID: UUID? = nil
    ) {
        self.id = id
        self.circleID = circleID
        self.title = title
        self.authorLine = authorLine
        self.pitchNote = pitchNote
        self.chosen = chosen
        self.createdAt = createdAt
        self.readingLane = readingLane
        self.stopMark = stopMark
        self.endingClosed = endingClosed
        self.suggestedBySeatID = suggestedBySeatID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        circleID = try container.decode(UUID.self, forKey: .circleID)
        title = try container.decode(String.self, forKey: .title)
        authorLine = container.soft(.authorLine, "")
        pitchNote = container.soft(.pitchNote, "")
        chosen = container.soft(.chosen, false)
        createdAt = container.soft(.createdAt, Date())
        let laneRaw = container.soft(.readingLane, "")
        readingLane = PloomReadingLane(rawValue: laneRaw) ?? .queue
        stopMark = container.soft(.stopMark, "")
        endingClosed = container.soft(.endingClosed, false)
        suggestedBySeatID = container.soft(.suggestedBySeatID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(circleID, forKey: .circleID)
        try container.encode(title, forKey: .title)
        try container.encode(authorLine, forKey: .authorLine)
        try container.encode(pitchNote, forKey: .pitchNote)
        try container.encode(chosen, forKey: .chosen)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(readingLane.rawValue, forKey: .readingLane)
        try container.encode(stopMark, forKey: .stopMark)
        try container.encode(endingClosed, forKey: .endingClosed)
        try container.encodeIfPresent(suggestedBySeatID, forKey: .suggestedBySeatID)
    }

    private enum CodingKeys: String, CodingKey {
        case id, circleID, title, authorLine, pitchNote, chosen, createdAt
        case readingLane, stopMark, endingClosed, suggestedBySeatID
    }
}

struct NexilMarginLeaf: Codable, Identifiable, Equatable {
    var id: UUID
    var gatheringID: UUID
    var title: String
    var points: String
    var savedAt: Date
    var quoteLine: String
    var pageLabel: String
    var reaction: String
    var spoilerChapter: String
    var spoilerLifted: Bool

    var spoilerSealed: Bool {
        !BrindleFieldCheck.trimmed(spoilerChapter).isEmpty && !spoilerLifted
    }

    var previewLine: String {
        let quote = BrindleFieldCheck.trimmed(quoteLine)
        if !quote.isEmpty { return quote }
        let reactionLine = BrindleFieldCheck.trimmed(reaction)
        if !reactionLine.isEmpty { return reactionLine }
        return points
    }

    init(
        id: UUID,
        gatheringID: UUID,
        title: String,
        points: String,
        savedAt: Date,
        quoteLine: String = "",
        pageLabel: String = "",
        reaction: String = "",
        spoilerChapter: String = "",
        spoilerLifted: Bool = false
    ) {
        self.id = id
        self.gatheringID = gatheringID
        self.title = title
        self.points = points
        self.savedAt = savedAt
        self.quoteLine = quoteLine
        self.pageLabel = pageLabel
        self.reaction = reaction
        self.spoilerChapter = spoilerChapter
        self.spoilerLifted = spoilerLifted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        gatheringID = try container.decode(UUID.self, forKey: .gatheringID)
        title = try container.decode(String.self, forKey: .title)
        points = container.soft(.points, "")
        savedAt = container.soft(.savedAt, Date())
        quoteLine = container.soft(.quoteLine, "")
        pageLabel = container.soft(.pageLabel, "")
        reaction = container.soft(.reaction, "")
        spoilerChapter = container.soft(.spoilerChapter, "")
        spoilerLifted = container.soft(.spoilerLifted, false)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gatheringID, forKey: .gatheringID)
        try container.encode(title, forKey: .title)
        try container.encode(points, forKey: .points)
        try container.encode(savedAt, forKey: .savedAt)
        try container.encode(quoteLine, forKey: .quoteLine)
        try container.encode(pageLabel, forKey: .pageLabel)
        try container.encode(reaction, forKey: .reaction)
        try container.encode(spoilerChapter, forKey: .spoilerChapter)
        try container.encode(spoilerLifted, forKey: .spoilerLifted)
    }

    private enum CodingKeys: String, CodingKey {
        case id, gatheringID, title, points, savedAt
        case quoteLine, pageLabel, reaction, spoilerChapter, spoilerLifted
    }
}

enum BrindleVaultKey {
    static let seenIntro = "brindle.qorvex.seenIntro.v1"
    static let circles = "brindle.qorvex.circles.v1"
    static let gatherings = "brindle.qorvex.gatherings.v1"
    static let slips = "brindle.qorvex.slips.v1"
    static let leaves = "brindle.qorvex.leaves.v1"
    static let activeCircle = "brindle.qorvex.activeCircle.v1"
}

extension Notification.Name {
    static let dataReset = Notification.Name("brindle.qorvex.dataReset")
}

enum QuillDateInk {
    static func medium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }
}

enum BrindleFieldCheck {
    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func required(_ text: String, hint: String) -> String? {
        trimmed(text).isEmpty ? hint : nil
    }

    static func lines(from note: String) -> [String] {
        note.split(whereSeparator: \.isNewline)
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }
    }
}

private extension KeyedDecodingContainer {
    func soft<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        do {
            return try decodeIfPresent(T.self, forKey: key) ?? fallback
        } catch {
            return fallback
        }
    }

    func soft<T: Decodable>(_ key: Key) -> T? {
        do {
            return try decodeIfPresent(T.self, forKey: key)
        } catch {
            return nil
        }
    }
}

enum QvMantleBrindleModels4541f {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 14
        let tape = [18, 11, 3, 18]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-678-\(span % 17)")
    }
}
