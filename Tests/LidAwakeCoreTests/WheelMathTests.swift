import Testing
@testable import LidAwakeCore

@Suite struct WheelMathTests {
    @Test func indexRoundsToNearest() {
        #expect(WheelMath.index(forOffset: 0, rowHeight: 36, count: 7) == 0)
        #expect(WheelMath.index(forOffset: 17, rowHeight: 36, count: 7) == 0)
        #expect(WheelMath.index(forOffset: 19, rowHeight: 36, count: 7) == 1)
        #expect(WheelMath.index(forOffset: 108, rowHeight: 36, count: 7) == 3)
    }

    @Test func indexClampsAtEnds() {
        #expect(WheelMath.index(forOffset: -50, rowHeight: 36, count: 7) == 0)
        #expect(WheelMath.index(forOffset: 10_000, rowHeight: 36, count: 7) == 6)
        #expect(WheelMath.index(forOffset: 10, rowHeight: 36, count: 0) == 0)
    }

    @Test func offsetRoundTrip() {
        for i in 0..<7 {
            #expect(WheelMath.index(forOffset: WheelMath.offset(forIndex: i, rowHeight: 36), rowHeight: 36, count: 7) == i)
        }
    }

    @Test func fadeAtCentreAndFar() {
        let centre = WheelMath.fade(distance: 0, rowHeight: 36)
        #expect(centre.opacity == 1 && centre.scale == 1)
        let one = WheelMath.fade(distance: 36, rowHeight: 36)
        #expect(abs(one.opacity - 0.55) < 0.0001 && abs(one.scale - 0.88) < 0.0001)
        let far = WheelMath.fade(distance: 500, rowHeight: 36)
        #expect(abs(far.opacity - 0.25) < 0.0001 && abs(far.scale - 0.78) < 0.0001)
        let half = WheelMath.fade(distance: 18, rowHeight: 36)
        #expect(abs(half.opacity - 0.775) < 0.0001)
        #expect(WheelMath.fade(distance: -36, rowHeight: 36).opacity == one.opacity)
    }
}
