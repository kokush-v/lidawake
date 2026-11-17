import Foundation

/// Geometry of the wheel picker. Offset 0 has the first item in the centre; it grows as the wheel scrolls down.
public enum WheelMath {
    /// The item nearest to the centre for a scroll offset, clamped to the list.
    public static func index(forOffset offset: Double, rowHeight: Double, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(Int((offset / rowHeight).rounded()), 0), count - 1)
    }

    public static func offset(forIndex index: Int, rowHeight: Double) -> Double {
        Double(index) * rowHeight
    }

    /// How faded and shrunk a row is, by its distance in points from the centre.
    public static func fade(distance: Double, rowHeight: Double) -> (opacity: Double, scale: Double) {
        let rows = min(abs(distance) / rowHeight, 2)
        if rows <= 1 {
            return (1 - 0.45 * rows, 1 - 0.12 * rows)
        }
        let t = rows - 1
        return (0.55 - 0.30 * t, 0.88 - 0.10 * t)
    }
}
