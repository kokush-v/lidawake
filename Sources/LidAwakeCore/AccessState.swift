import Foundation

/// Whether the narrow sudo rule (exactly the two `pmset -a disablesleep` commands) is in effect.
public enum AccessState: Equatable {
    case granted(rule: String)
    case missing
}

public enum AccessChecker {
    public static let sudoPath = "/usr/bin/sudo"

    /// The only privileged commands the app may run.
    public static let allowedArguments: [[String]] = [
        ["-a", "disablesleep", "0"],
        ["-a", "disablesleep", "1"],
    ]

    public static let fallbackRule =
        "NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"

    /// Granted iff `sudo -n -l <command>` succeeds for both allowed commands.
    public static func check(using runner: CommandRunner) -> AccessState {
        for args in allowedArguments {
            let result = runner.run(sudoPath, ["-n", "-l", SleepState.pmsetPath] + args)
            guard result.succeeded else { return .missing }
        }
        return .granted(rule: ruleInEffect(using: runner))
    }

    static func ruleInEffect(using runner: CommandRunner) -> String {
        let result = runner.run(sudoPath, ["-n", "-l"])
        guard result.succeeded else { return fallbackRule }
        let lines = result.stdout
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.contains("pmset") }
        return lines.isEmpty ? fallbackRule : lines.joined(separator: "\n")
    }
}
