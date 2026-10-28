import SwiftUI
import UIKit

enum QuillTypingFold {
    static func resign() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum QuillTap {
    static func confirm() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct QuillWindowTapFold: UIViewRepresentable {
    func makeUIView(context: Context) -> FoldView {
        FoldView()
    }

    func updateUIView(_ uiView: FoldView, context: Context) {}

    final class FoldView: UIView, UIGestureRecognizerDelegate {
        private var tap: UITapGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, tap == nil else { return }
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(endTyping))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
            tap = recognizer
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            nil
        }

        @objc private func endTyping() {
            QuillTypingFold.resign()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var node: UIView? = touch.view
            while let current = node {
                if current is UITextField || current is UITextView || current is UIControl || current is UIDatePicker {
                    return false
                }
                let name = NSStringFromClass(type(of: current))
                if name.contains("TextField") || name.contains("TextView") {
                    return false
                }
                node = current.superview
            }
            return true
        }
    }
}

extension View {
    func quillKeyboardDone() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        QuillTypingFold.resign()
                    }
                }
            }
    }
}

enum QvMantleQuillTypingFolddc120 {
    struct Slip {
        var span: Int
        var token: String
    }

    static func braid(_ seed: Int) -> Int {
        var acc = seed &+ 16
        let tape = [18, 15, 3, 3]
        for step in tape {
            acc = (acc &* step) ^ (acc >> 2)
        }
        return acc & 0xFFFF
    }

    static func slip(for seed: Int) -> Slip {
        let span = braid(seed)
        return Slip(span: span, token: "brindle-251-\(span % 16)")
    }
}
