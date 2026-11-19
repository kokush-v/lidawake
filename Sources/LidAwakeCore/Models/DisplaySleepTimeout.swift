import Foundation

/// The "turn display off after" setting as reported by `pmset -g`.
public enum DisplaySleepTimeout {
    /// Seconds before the display turns off; `0` means never, `nil` means the line is missing or unreadable.
    public static func parse(pmsetOutput: String) -> TimeInterval? {
        for line in pmsetOutput.split(separator: "\n") {
            let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard tokens.count >= 2, tokens[0] == "displaysleep" else { continue }
            guard let minutes = Int(tokens[1]), minutes >= 0 else { return nil }
            return TimeInterval(minutes * 60)
        }
        return nil
    }
}
