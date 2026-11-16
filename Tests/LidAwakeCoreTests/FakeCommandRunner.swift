import LidAwakeCore

/// Scripted runner: responses are keyed by "executable arg1 arg2 ...".
final class FakeCommandRunner: CommandRunner {
    var responses: [String: CommandResult] = [:]
    /// Sequential results for a key, consumed in order (the last one repeats).
    var sequences: [String: [CommandResult]] = [:]
    private(set) var calls: [String] = []
    var fallback = CommandResult(exitCode: 127, stderr: "not scripted")

    func run(_ executable: String, _ arguments: [String]) -> CommandResult {
        let key = ([executable] + arguments).joined(separator: " ")
        calls.append(key)
        if var seq = sequences[key], !seq.isEmpty {
            let next = seq.count > 1 ? seq.removeFirst() : seq[0]
            sequences[key] = seq
            return next
        }
        return responses[key] ?? fallback
    }
}
