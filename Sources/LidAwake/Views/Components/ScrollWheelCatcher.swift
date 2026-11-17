import AppKit
import SwiftUI

/// Reports mouse-wheel and trackpad scrolling over its own area, which SwiftUI does not expose on macOS 13.
/// Place it as a `.background` of the view that should react.
struct ScrollWheelCatcher: NSViewRepresentable {
    /// `delta` is positive when the content should move down; `precise` is true for trackpads.
    var onScroll: (_ delta: CGFloat, _ precise: Bool) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.onScroll = onScroll
    }

    final class CatcherView: NSView {
        var onScroll: (CGFloat, Bool) -> Void = { _, _ in }
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, event.window === self.window,
                      self.bounds.contains(self.convert(event.locationInWindow, from: nil)) else { return event }
                self.onScroll(event.scrollingDeltaY, event.hasPreciseScrollingDeltas)
                return nil  // the wheel is ours while the pointer is over it
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
