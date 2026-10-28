import SwiftUI

struct ContentView: View {
    @StateObject private var vault = BrindleCircleVault()

    var body: some View {
        Group {
            if vault.hasSeenFolioIntro {
                QuillRootDeck()
            } else {
                FolioIntroPager()
            }
        }
        .environmentObject(vault)
        .background {
            QuillWindowTapFold()
        }
    }
}

enum QvMantleContentView755b0 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 10
        let tape = [4, 4, 16, 7]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-150-\(span % 22)")
    }
}
