import Foundation

/// Whether the narrow sudo rule (exactly the two `pmset -a disablesleep` commands) is in effect.
public enum AccessState: Equatable {
    case granted(rule: String)
    case missing
}

public enum AccessChecker {
    public static let sudoPath = "/usr/bin/sudo"

    public static let commandOff = "/usr/bin/pmset -a disablesleep 0"
    public static let commandOn = "/usr/bin/pmset -a disablesleep 1"

    public static let fallbackRule = "NOPASSWD: \(commandOff), \(commandOn)"

    /// Granted iff `sudo -n -l` lists both commands as NOPASSWD (explicitly or via `ALL`).
    ///
    /// `sudo -l <command>` is not used: it also succeeds for commands that are allowed only with a
    /// password, which would wrongly report access on Macs that have any other NOPASSWD entry.
    public static func check(using runner: CommandRunner) -> AccessState {
        let result = runner.run(sudoPath, ["-n", "-l"])
        guard result.succeeded else { return .missing }
        return evaluate(listing: result.stdout)
    }

    static func evaluate(listing: String) -> AccessState {
        var allowed = Set<String>()
        var ruleLines: [String] = []
        for rawLine in listing.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let tag = line.range(of: "NOPASSWD:") else { continue }
            // Commands after a later "PASSWD:" tag need a password again.
            var commands = String(line[tag.upperBound...])
            if let again = commands.range(of: " PASSWD:") { commands = String(commands[..<again.lowerBound]) }
            let items = commands.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let relevant = items.filter { $0 == commandOff || $0 == commandOn || $0 == "ALL" }
            guard !relevant.isEmpty else { continue }
            allowed.formUnion(relevant)
            ruleLines.append(line)
        }
        let everything = allowed.contains("ALL")
        guard everything || (allowed.contains(commandOff) && allowed.contains(commandOn)) else {
            return .missing
        }
        return .granted(rule: ruleLines.joined(separator: "\n"))
    }
}
