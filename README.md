# local-memo

A CLI that saves plain-text memos scoped to the current working directory. Run it from any project and its memos stay private to that project — a different directory never sees them.

## Storage Layout

- Root: `~/.localmemo/` (override with `LOCALMEMO_HOME`)
- Config: `~/.localmemo/config.json`
- Memos: `~/.localmemo/<hash>/<key>.txt` (the body, as plain text) + `~/.localmemo/<hash>/.meta/<key>.json` (TTL and timestamps)

`<hash>` is the first 16 hex characters of SHA-256 over the current working directory's normalized, symlink-resolved absolute path. It is **one-way**: the original path is never stored anywhere, so a hash directory cannot be mapped back to the project it belongs to. The same project path always hashes to the same directory, so memos persist across sessions without any setup.

## Commands

```
local-memo set <key> [value] [--ttl <duration>] [--no-overwrite]
local-memo get <key> [--include-expired]
local-memo list [--show-expired] [--long] [--keys-only]
local-memo delete <key>... [--all] [--force]     (alias: rm)
local-memo cleanup [--all-projects] [--dry-run]
local-memo path [--root]
local-memo config init [--force]
local-memo config show
local-memo config set <key> <value>
local-memo config path
```

Every command accepts `--project <path>` (scope to a directory other than cwd) and `--json` (machine-readable output).

### set

Saves `value` under `key` for the current project. Omit `value` (or pass `-`) to read from stdin:

```sh
local-memo set todo "buy milk"
echo "long note" | local-memo set notes
local-memo set expiring "gone in an hour" --ttl 1h
```

TTL syntax: `<int><unit>` segments with no separator, units `s m h d w` (e.g. `30m`, `2h`, `7d`, `1d12h`). `never` or `0` means no expiry. Omitting `--ttl` uses `config.default_ttl`.

By default `set` overwrites an existing key; pass `--no-overwrite` to fail instead (exit code 3). An **expired** memo is treated as absent for this check — overwriting it always succeeds.

### get

Prints a memo's raw value to stdout (no trailing newline added). Exits 4 if the key doesn't exist, 5 if it has expired (see [TTL and expiration](#ttl-and-expiration)). `--include-expired` returns the value anyway without deleting it.

### list

Lists the current project's memos as a table (`key`, `expires`, and `created` with `--long`). `--show-expired` includes expired entries (marked `(expired)`); `--keys-only` prints one key per line.

### delete (rm)

Deletes one or more keys, or every memo in the project with `--all` (prompts for confirmation unless `--force` is passed).

### cleanup

Physically deletes every expired memo — scoped to the current project by default, or every project under the memo root with `--all-projects`. `--dry-run` reports what would be deleted without touching disk.

### path

Prints the current project's memo directory (`~/.localmemo/<hash>/`). `--root` prints `~/.localmemo` itself instead.

## config.json

```json
{
  "schema_version": 1,
  "default_ttl": null,
  "root_directory": null,
  "expired_policy": "lazy_delete",
  "auto_cleanup": false,
  "hash_length": 16,
  "max_value_bytes": 1048576,
  "default_output": "text"
}
```

| Key | Meaning |
|---|---|
| `default_ttl` | TTL applied when `set --ttl` is omitted. `null` means no expiry. |
| `root_directory` | Where memo bodies are stored, if not `~/.localmemo`. `config.json` itself always stays under `~/.localmemo` (or `$LOCALMEMO_HOME`). |
| `expired_policy` | `hide` (keep files, treat as gone by default), `lazy_delete` (physically delete on first touch), or `keep` (never expire). |
| `auto_cleanup` | When `true`, every command sweeps the current project's expired memos before running. |
| `hash_length` | Leading hex characters of the project path hash used as its directory name. **Do not change this once memos exist** — `config set hash_length` refuses to while any memo is present, since it would orphan them. |
| `max_value_bytes` | Upper bound on a memo's value size. |
| `default_output` | `text` or `json`; used when a command's `--json` flag is omitted. |

The file is optional — commands work with built-in defaults if it's missing. Unknown keys are ignored, so an old `config.json` stays valid after new keys are added.

## TTL and expiration

`expired_policy` decides what happens once a memo's `expires_at` has passed:

- **`lazy_delete`** (default): the first command that touches an expired memo (`get`, `list`) deletes its files on the spot and reports it as gone.
- **`hide`**: expired memos stay on disk but are excluded from `list` and fail `get` (exit 5) unless `--show-expired` / `--include-expired` is used.
- **`keep`**: expiration is informational only; memos are never hidden or deleted automatically. Use `cleanup` to remove them explicitly.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/Ryu0118/local-memo/main/install.sh | bash
```

### Build from source

Requires macOS 26+ and Swift 6.2.

```sh
git clone https://github.com/Ryu0118/local-memo.git
cd local-memo
swift build -c release
cp .build/release/local-memo /usr/local/bin/local-memo
```

## Development

```sh
make install-commands
make format
make lint
make test
make e2e-test
make check
```

## License

MIT. See [LICENSE](LICENSE).
