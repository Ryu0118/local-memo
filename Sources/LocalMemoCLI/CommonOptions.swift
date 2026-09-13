import ArgumentParser

/// Options shared by every subcommand: which project to scope to, and output format.
package struct CommonOptions: ParsableArguments {
    @Option(name: .long, help: "Directory to scope memos to (defaults to the current directory).", completion: .directory)
    package var project: String?

    @Flag(name: .long, help: "Emit machine-readable JSON on stdout instead of human-readable text.")
    package var json = false

    package init() {}
}
