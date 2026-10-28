import SwiftUI

struct CircleDigestBoard: View {
    @EnvironmentObject private var vault: BrindleCircleVault
    @State private var showFirstSitting = false

    private var circleID: UUID? { vault.activeCircleID }

    private var scopedGatherings: [BrindleGatheringSlip] {
        guard let circleID else { return [] }
        return vault.gatherings(for: circleID)
    }

    private var scopedSlips: [PloomTitleSlip] {
        guard let circleID else { return [] }
        return vault.slips(for: circleID)
    }

    private var noteCount: Int {
        let ids = Set(scopedGatherings.map(\.id))
        return vault.leaves.filter { ids.contains($0.gatheringID) }.count
    }

    private var currentSlip: PloomTitleSlip? {
        guard let circleID else { return nil }
        return vault.currentSlip(in: circleID)
    }

    private var upcoming: [BrindleGatheringSlip] {
        scopedGatherings.filter { $0.heldOn >= Date() }.sorted { $0.heldOn < $1.heldOn }
    }

    private var latestVerdict: BrindleGatheringSlip? {
        scopedGatherings
            .filter { $0.clubScore != nil || !BrindleFieldCheck.trimmed($0.verdictLine).isEmpty }
            .sorted { $0.heldOn > $1.heldOn }
            .first
    }

    private var finished: [PloomTitleSlip] {
        scopedSlips.filter { $0.readingLane == .done }
    }

    private var hasAnything: Bool {
        !scopedGatherings.isEmpty || !scopedSlips.isEmpty || noteCount > 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let circle = vault.activeCircle {
                    NavigationLink {
                        CircleCradleBoard()
                    } label: {
                        QuillPaperCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active circle")
                                    .font(.system(size: 12, weight: .semibold, design: .serif))
                                    .foregroundColor(.secondary)
                                Text(circle.title)
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                if !circle.placeHint.isEmpty {
                                    Text(circle.placeHint)
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                }
                                if let host = circle.hostName {
                                    Text("Host · \(host)")
                                        .font(.system(size: 15, weight: .semibold, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                if vault.activeCircle == nil {
                    QuillEmptyMark(
                        symbol: "chart.bar.fill",
                        title: "Nothing to summarize yet",
                        detail: "Name a circle, choose the first book, and set a date."
                    )
                    QuillPrimaryButton(title: "Start a circle", identifier: "folio.startSitting") {
                        showFirstSitting = true
                    }
                } else if !hasAnything {
                    QuillEmptyMark(
                        symbol: "book.closed",
                        title: "Nothing to summarize yet",
                        detail: "Schedule a gathering or add a title. The summary here comes only from what you save."
                    )
                } else {
                    readingNow
                    nextGathering
                    if let verdict = latestVerdict {
                        verdictCard(verdict)
                    }
                    if upcoming.count > 1 {
                        Text("Also coming up")
                            .font(.system(size: 18, weight: .semibold))
                        ForEach(Array(upcoming.dropFirst())) { item in
                            gatheringLink(item)
                        }
                    }
                    if !finished.isEmpty {
                        Text("Finished")
                            .font(.system(size: 18, weight: .semibold))
                        ForEach(finished) { slip in
                            NavigationLink {
                                PloomSlipDetail(slipID: slip.id)
                            } label: {
                                QuillPaperCard {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(slip.title)
                                            .font(.system(size: 16, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        Text(slip.authorLine)
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
            }
            .padding(16)
        }
        .navigationTitle("Pulse")
        .navigationBarTitleDisplayMode(.inline)
        .quillLaidPaper()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                QuillOptionsButton()
            }
        }
        .sheet(isPresented: $showFirstSitting) {
            FolioFirstSitting()
        }
    }

    @ViewBuilder
    private var readingNow: some View {
        Text("Reading now")
            .font(.system(size: 18, weight: .semibold))
        if let slip = currentSlip {
            NavigationLink {
                PloomSlipDetail(slipID: slip.id)
            } label: {
                QuillPaperCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(slip.title)
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                        Text(slip.authorLine)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.secondary)
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
            Text("Mark a title as reading now on the shelf.")
                .font(.system(size: 15, design: .serif))
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }

    @ViewBuilder
    private var nextGathering: some View {
        Text("Next gathering")
            .font(.system(size: 18, weight: .semibold))
        if let item = upcoming.first {
            gatheringLink(item, showsStop: true)
        } else {
            Text("No gathering is scheduled.")
                .font(.system(size: 15, design: .serif))
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }

    private func gatheringLink(_ item: BrindleGatheringSlip, showsStop: Bool = false) -> some View {
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
                    if let slipID = item.linkedSlipID, let slip = vault.slip(id: slipID) {
                        Text(slip.title)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                        if showsStop, !slip.stopMark.isEmpty {
                            Text("Read to \(slip.stopMark)")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func verdictCard(_ item: BrindleGatheringSlip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last verdict")
                .font(.system(size: 18, weight: .semibold))
            NavigationLink {
                GatheringDetailLeaf(gatheringID: item.id)
            } label: {
                QuillPaperCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(QuillDateInk.medium(item.heldOn))
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                        if let score = item.clubScore {
                            Text("Score \(score) of 5")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                        if !item.verdictLine.isEmpty {
                            Text(item.verdictLine)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                        if let slipID = item.linkedSlipID, let slip = vault.slip(id: slipID) {
                            Text(slip.title)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

enum QvMantleCircleDigestBoarde32ee {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 7
        let tape = [17, 18, 16, 4]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 3)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-954-\(span % 11)")
    }
}
