import LocalMemoCLI

@main
struct LocalMemo {
    static func main() async throws {
        await LocalMemoCommand.main()
    }
}
