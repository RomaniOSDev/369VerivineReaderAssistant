import UIKit

enum VeyraLinkHarbor {
    static let privacy = "https://verivinereader369assistant.site/privacy/488"
    static let terms = "https://verivinereader369assistant.site/terms/488"

    static func openPrivacy() {
        if let url = URL(string: privacy) {
            UIApplication.shared.open(url)
        }
    }

    static func openTerms() {
        if let url = URL(string: terms) {
            UIApplication.shared.open(url)
        }
    }
}

enum QvMantleVeyraLinkHarbordf088 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 7
        let tape = [11, 19, 18, 13]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 3)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-349-\(span % 8)")
    }
}
