import Foundation
import Interaction

/// local-memo's default interaction: a plain `Terminal` while stdin is a TTY, and a
/// fail-fast guard when it is not.
///
/// Agents and CI pipe or close stdin, so an interactive prompt would either hang forever
/// waiting for keystrokes or spin on end-of-input errors. When a prompt is reached without a
/// TTY, this fails loudly instead: it prints the prompt's own question and exits non-zero.
///
/// Output methods (`write`, `writeStatus`, `writeTable`) pass through unconditionally — only
/// *input* requires a TTY.
public struct GuardedTerminal: InteractionProviding {
    private let base = Terminal()
    private let isTTY: @Sendable () -> Bool

    public init(isTTY: @escaping @Sendable () -> Bool = { isatty(STDIN_FILENO) != 0 }) {
        self.isTTY = isTTY
    }

    /// Writes styled text to the terminal.
    public func write(_ text: StyledText) {
        base.write(text)
    }

    /// Writes a status line (success/warning/failure) to the terminal.
    public func writeStatus(_ status: Status, _ message: StyledText) {
        base.writeStatus(status, message)
    }

    /// Renders a table to the terminal.
    public func writeTable(_ table: Table) {
        base.writeTable(table)
    }

    /// Reads free-text input, failing fast if stdin is not a TTY.
    public func readText(_ prompt: TextPrompt) async -> String {
        guardInteractive(question: prompt.message.plainText)
        return await base.readText(prompt)
    }

    /// Reads a yes/no confirmation, failing fast if stdin is not a TTY.
    public func confirm(_ prompt: ConfirmationPrompt) -> Bool {
        guardInteractive(question: prompt.question.plainText)
        return base.confirm(prompt)
    }

    /// Reads a single choice from a list, failing fast if stdin is not a TTY.
    public func choose<Option>(_ prompt: ChoicePrompt<Option>) -> Option {
        guardInteractive(question: prompt.question.plainText)
        return base.choose(prompt)
    }

    /// Reads multiple choices from a list, failing fast if stdin is not a TTY.
    public func chooseMany<Option>(_ prompt: MultipleChoicePrompt<Option>) -> [Option] {
        guardInteractive(question: prompt.question.plainText)
        return base.chooseMany(prompt)
    }

    /// The message shown when a prompt is reached without a TTY. Split out so tests can pin
    /// the wording without triggering the process exit.
    static func nonInteractiveFailureMessage(question: String) -> String {
        """
        Error: interactive input required (\"\(question)\"), but stdin is not a TTY.
        Pass the missing value as a command-line flag instead — run the command with --help to see the options.
        """
    }

    private func guardInteractive(question: String) {
        guard !isTTY() else { return }
        FileHandle.standardError.write(Data((Self.nonInteractiveFailureMessage(question: question) + "\n").utf8))
        exit(EX_USAGE)
    }
}
