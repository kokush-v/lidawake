import Foundation

/// The `SleepDisabled` setting as reported by `pmset -g` (the single source of truth).
public enum SleepState: Equatable {
    case awake    // SleepDisabled = 1: the Mac will not sleep on lid close
    case sleep    // SleepDisabled = 0: normal behavior
    case unknown  // could not be read

    public static let pmsetPath = "/usr/bin/pmset"

    /// Parses `pmset -g` output. When the field is absent from otherwise valid output
    /// (the system default, never set), sleep is allowed.
    public static func parse(pmsetOutput: String) -> SleepState {
        for line in pmsetOutput.split(separator: "\n") {
            let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard tokens.count >= 2, tokens[0] == "SleepDisabled" else { continue }
            switch tokens[1] {
            case "1": return .awake
            case "0": return .sleep
            default: return .unknown
            }
        }
        return pmsetOutput.contains("Currently in use:") ? .sleep : .unknown
    }

    public static func read(using runner: CommandRunner) -> SleepState {
        let result = runner.run(pmsetPath, ["-g"])
        guard result.succeeded else { return .unknown }
        return parse(pmsetOutput: result.stdout)
    }
}
