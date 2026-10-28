import SwiftUI

extension Color {
    static let brindlePaper = Color("AppBackground")
    static let brindleCard = Color("AppSurface")
    static let brindleInk = Color("AppPrimary")
    static let brindleRibbon = Color("AppAccent")
}

enum QvMantleBrindlePalette35e63 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 16
        let tape = [7, 11, 12, 14]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-205-\(span % 24)")
    }
}
