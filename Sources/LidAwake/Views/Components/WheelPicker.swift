import LidAwakeCore
import SwiftUI

/// An iOS-style wheel: five rows with the selection in the centre, faded and shrunk neighbours,
/// snapping to the nearest value after a drag or a wheel scroll. Clicking a row selects it.
struct WheelPicker<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var wheel = WheelState()

    private let rowHeight: Double = 30
    private let visibleRows = 5

    private var selectedIndex: Int { items.firstIndex(of: selection) ?? 0 }
    private var snapAnimation: Animation? { reduceMotion ? nil : .easeOut(duration: PanelTheme.motionDuration) }
    private var maxOffset: Double { Double(max(items.count - 1, 0)) * rowHeight }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(PanelTheme.groupFill)
                .frame(height: rowHeight)
                .padding(.horizontal, 8)
            ForEach(items.indices, id: \.self) { index in row(index) }
        }
        .frame(height: rowHeight * Double(visibleRows))
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(drag)
        .background(ScrollWheelCatcher { delta, precise in scroll(delta, precise: precise) })
        .onAppear { wheel.offset = WheelMath.offset(forIndex: selectedIndex, rowHeight: rowHeight) }
        .onChange(of: selection) { _ in
            guard !wheel.isInteracting else { return }
            withAnimation(snapAnimation) { wheel.offset = WheelMath.offset(forIndex: selectedIndex, rowHeight: rowHeight) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue(label(selection))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: commit(selectedIndex - 1)
            case .decrement: commit(selectedIndex + 1)
            @unknown default: break
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let distance = Double(index) * rowHeight - wheel.offset
        let look = WheelMath.fade(distance: distance, rowHeight: rowHeight)
        return Text(label(items[index]))
            .font(.body.weight(abs(distance) < rowHeight / 2 ? .semibold : .regular))
            .scaleEffect(look.scale)
            .opacity(look.opacity)
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .offset(y: distance)
            .onTapGesture { commit(index) }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                wheel.cancelSettle()
                if wheel.dragStart == nil { wheel.dragStart = wheel.offset }
                wheel.offset = clamped((wheel.dragStart ?? 0) - Double(value.translation.height))
            }
            .onEnded { value in
                let start = wheel.dragStart ?? wheel.offset
                wheel.dragStart = nil
                let target = start - Double(value.predictedEndTranslation.height)
                commit(WheelMath.index(forOffset: target, rowHeight: rowHeight, count: items.count))
            }
    }

    private func scroll(_ delta: CGFloat, precise: Bool) {
        guard wheel.dragStart == nil else { return }
        wheel.offset = clamped(wheel.offset - Double(delta) * (precise ? 1 : 12))
        wheel.settle(after: 0.12) {
            commit(WheelMath.index(forOffset: wheel.offset, rowHeight: rowHeight, count: items.count))
        }
    }

    /// Lets the wheel overshoot the ends a little while it is being moved.
    private func clamped(_ offset: Double) -> Double {
        min(max(offset, -rowHeight * 0.4), maxOffset + rowHeight * 0.4)
    }

    private func commit(_ index: Int) {
        guard !items.isEmpty else { return }
        let index = min(max(index, 0), items.count - 1)
        wheel.cancelSettle()
        withAnimation(snapAnimation) { wheel.offset = WheelMath.offset(forIndex: index, rowHeight: rowHeight) }
        if items[index] != selection { selection = items[index] }
    }
}

/// The wheel's live scroll position and the pending "snap when scrolling stops" action.
final class WheelState: ObservableObject {
    @Published var offset: Double = 0
    var dragStart: Double?
    private var pending: DispatchWorkItem?

    var isInteracting: Bool { dragStart != nil || pending != nil }

    func settle(after delay: TimeInterval, _ action: @escaping () -> Void) {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.pending = nil
            action()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func cancelSettle() {
        pending?.cancel()
        pending = nil
    }
}
