import Foundation

public enum PrivilegeResult: Equatable {
    case success
    case cancelled
    case invalidArgument
    case validationFailed
    case installFailed(String)
}

public protocol PrivilegeActions {
    func grant(user: String) -> PrivilegeResult
    func revoke() -> PrivilegeResult
}

public extension AccessChecker {
    /// The exact sudoers line the grant script installs.
    static func ruleLine(user: String) -> String {
        "\(user) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
    }
}

/// Runs the embedded grant/revoke script text as root through the standard macOS
/// administrator prompt. It never executes a script file from disk.
public struct PrivilegeInstaller: PrivilegeActions {
    public static let osascriptPath = "/usr/bin/osascript"

    private let runner: CommandRunner

    public init(runner: CommandRunner) {
        self.runner = runner
    }

    public func grant(user: String) -> PrivilegeResult {
        run(
            scriptText: EmbeddedScripts.grantAccess,
            arguments: [user],
            prompt: "LidAwake wants to allow switching your Mac's sleep mode without asking for a password. "
                + "It adds one rule: \(user) may run only \"pmset -a disablesleep 0\" and \"pmset -a disablesleep 1\"."
        )
    }

    public func revoke() -> PrivilegeResult {
        run(
            scriptText: EmbeddedScripts.revokeAccess,
            arguments: [],
            prompt: "LidAwake wants to remove its permission to switch your Mac's sleep mode."
        )
    }

    /// Single-quotes a string for `/bin/sh`, so any text round-trips unchanged.
    static func shellQuote(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// The shell command line passed to `do shell script`: `/bin/sh -c '<script text>' sh <args>`.
    static func commandLine(scriptText: String, arguments: [String]) -> String {
        (["/bin/sh", "-c", shellQuote(scriptText), "sh"] + arguments.map(shellQuote)).joined(separator: " ")
    }

    /// osascript arguments. The command line and the prompt travel as script arguments (`argv`),
    /// so no AppleScript string escaping is involved.
    static func osascriptArguments(scriptText: String, arguments: [String], prompt: String) -> [String] {
        [
            "-e", "on run argv",
            "-e", "do shell script (item 1 of argv) with prompt (item 2 of argv) with administrator privileges",
            "-e", "end run",
            commandLine(scriptText: scriptText, arguments: arguments),
            prompt,
        ]
    }

    func run(scriptText: String, arguments: [String], prompt: String) -> PrivilegeResult {
        let result = runner.run(
            Self.osascriptPath,
            Self.osascriptArguments(scriptText: scriptText, arguments: arguments, prompt: prompt)
        )
        if result.succeeded { return .success }
        return Self.map(stderr: result.stderr)
    }

    /// `osascript` reports a failing shell script as "... (N)" with N the script's exit status.
    static func map(stderr: String) -> PrivilegeResult {
        let text = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let open = text.lastIndex(of: "("), text.hasSuffix(")") else {
            return .installFailed(text)
        }
        let code = Int(text[text.index(after: open)..<text.index(before: text.endIndex)])
        switch code {
        case -128: return .cancelled
        case 2: return .invalidArgument
        case 3: return .validationFailed
        default: return .installFailed(text)
        }
    }
}
