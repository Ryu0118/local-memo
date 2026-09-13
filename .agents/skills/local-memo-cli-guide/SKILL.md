---
name: local-memo-cli-guide
description: CLI usage guide for local-memo, a tool that saves plain-text memos scoped to the current working directory. Use when an agent or user wants to save/read/list/delete a project-local memo, set a TTL on a memo, configure ~/.localmemo/config.json, or clean up expired memos.
---

# local-memo CLI Guide

local-memo saves plain-text memos under `~/.localmemo/<hash>/<key>.txt`, where `<hash>` is a one-way SHA-256 hash of the current project's directory. Memos set from one project directory are never visible from another.

```
local-memo <subcommand>
  set       Save a memo.
  get       Print a memo's value.
  list      List memos for the current project.
  delete    Delete one or more memos (alias: rm).
  cleanup   Delete expired memos.
  path      Print the current project's memo directory.
  config    Manage ~/.localmemo/config.json.
```

Every command accepts `--project <path>` (scope to a directory other than cwd) and `--json` (machine-readable output).

## Common Operations

```sh
local-memo set todo "buy milk"
local-memo set todo "buy milk" --ttl 2h
echo "long note" | local-memo set notes
local-memo get todo
local-memo list --json
local-memo delete todo
local-memo delete --all --force
local-memo cleanup --dry-run
local-memo cleanup
```

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Unexpected failure |
| 2 | Invalid input (malformed key, TTL, or config value) |
| 3 | Already exists (`set --no-overwrite`, `config init` without `--force`) |
| 4 | Not found |
| 5 | Expired |
| 6 | I/O error |
| 64 | Argument parsing failure |

For agent use: `get`/`delete` failures are distinguishable via exit code without parsing stderr. Add `--json` to any command for a structured result on stdout.

## TTL Syntax

`<int><unit>` segments concatenated with no separator: `s` (seconds), `m` (minutes), `h` (hours), `d` (days), `w` (weeks). Examples: `30m`, `2h`, `7d`, `1d12h`. `never` or `0` means no expiry.

## Expiration Behavior

Controlled by `config.expired_policy` (default `lazy_delete`, see `config show`):
- `lazy_delete`: the first command to touch an expired memo deletes it and reports "expired" (exit 5), then "not found" (exit 4) on subsequent calls.
- `hide`: expired memos are hidden from `list`/`get` by default but not deleted; `--show-expired` / `--include-expired` reveals them.
- `keep`: memos never expire automatically; use `cleanup` to remove them explicitly.

## Config

```sh
local-memo config init            # write ~/.localmemo/config.json with defaults
local-memo config show            # print the effective config (file merged over defaults)
local-memo config set default_ttl 7d
local-memo config path            # print the config.json path
```

`config set hash_length` is refused while the current project has memos (it would orphan them). See the project README's config.json table for every key.

## Non-Interactive Use

`delete --all` prompts for confirmation unless stdin is a TTY-less context, in which case it fails fast rather than hanging — pass `--force` explicitly instead of relying on the prompt. `set` with no value argument reads from stdin, so pipe input rather than typing it interactively when scripting.
