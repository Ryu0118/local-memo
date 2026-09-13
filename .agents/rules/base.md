# local-memo - A Local Memo CLI

A CLI tool that saves plain-text memos scoped to the current working directory. Memos live under `~/.localmemo/<sha256(cwd)[0..<16]>/<key>.txt`, so the same key in different project directories never collides.

## Directory Structure

| Path | Purpose |
|------|---------|
| `Sources/local-memo/` | Entry point only - just calls LocalMemoCommand |
| `Sources/LocalMemoCLI/` | CLI command definitions (ArgumentParser). Thin layer, no business logic |
| `Sources/LocalMemoKit/` | **All implementation**. Storage, config parsing, TTL handling, runners |
| `Sources/LocalMemoKit/Config/` | `config.json` model, loading, and writing |
| `Sources/LocalMemoKit/Storage/` | Path hashing, memo file layout, read/write |
| `Sources/LocalMemoKit/TTL/` | TTL duration parsing and expiration policy |
| `Sources/LocalMemoKit/Runners/` | Command execution logic (e.g. `SetRunner.swift`) |
| `Tests/LocalMemoKitTests/` | Unit tests |
| `E2ETestsPackage/` | E2E tests (separate package). Run with `cd E2ETestsPackage && swift test` |

## Naming Conventions

| Pattern | Purpose |
|---------|---------|
| `*Runner.swift` | Command execution logic (e.g., `SetRunner.swift`) |
| `*ArgumentsValidator.swift` | Input validation before running |

## Storage Layout

- Root: `~/.localmemo/` (override with `LOCALMEMO_HOME`)
- Config: `~/.localmemo/config.json`
- Memos: `~/.localmemo/<hash>/<key>.txt` + `~/.localmemo/<hash>/.meta/<key>.json`
- `<hash>` is the first 16 hex characters of SHA-256 over the normalized, symlink-resolved cwd. It is one-way: the original path is never stored anywhere, so a hash directory cannot be mapped back to a project path.

## Available Skills

| Skill | When to use |
|-------|-------------|
| `local-memo-cli-guide` | CLI commands, config.json schema, TTL semantics |

## Notes

- Swift 6.2 / macOS 26+
- Use `package` access modifier for cross-module types
- `make lint` runs both SwiftLint and my-swift-linter. Install hooks with `make hooks`; pre-push runs `make my-lint`.
- No MCP server, no DocC generation, no template/plugin distribution in this project — CLI + dev harness only.

## Code Review Checklist

Apply these when reviewing or refactoring code in this repo:

- **Directory splits stay behavior-neutral.** Prefer pure `git mv` in its own commit before any content edit — git records clean renames, and a bisect/revert stays possible. Verify SPM still builds with no `Package.swift` change (it auto-discovers sources recursively).
- **No lone-file directories, no all-directory root.** Group ≥2-3 related files per subdirectory; keep the public entry point and single-file concerns at the module root rather than forcing them into a directory of one.
- **Comment the "why", not the "what".** Add comments only where logic has a non-obvious invariant or encodes an external spec (e.g. path hash normalization, TTL expiry semantics). Skip comments on self-explanatory code.
- **Don't extract abstractions from superficially similar code.** Before factoring out a shared helper, check what's actually identical across call sites vs. what only looks similar — if the guard condition, the non-shared branch, and the return shape all differ, the "dedup" adds an awkward helper for near-zero line savings. Leave near-duplicates alone unless the shared part is substantial.
- **Widening access (`private` → `internal`/`package`) to enable a file split is fine** as long as no `public` signature changes.
- **Re-run `swift build`, `swift test`, and `make lint` after every content-changing commit**, not just at the end — the pre-commit hook (`swiftlint --strict` + my-swift-linter) will hard-block a bad commit, and it's cheaper to catch drift immediately.
- **Check `docsync.yml` after moving or editing any file it tracks** (`docsync check` / `docsync update-checksum`) — moved source paths and edited files both invalidate its checksums, and the pre-commit hook fails the commit until resynced.
- **Clean up untracked cruft found along the way** (e.g. stray `.DS_Store`) as part of the same pass, even if unrelated to the main task.
