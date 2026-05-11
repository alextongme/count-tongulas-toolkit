# power-setup

> From [Count Tongula's Toolkit](https://alextong.me/toolkit) by [Alex Tong](https://alextong.me) — more at [alextong.me/newsletter](https://alextong.me/newsletter)

My actual Claude Code config. Copy mine.

Starts with the status line. Safety hooks and session logging land in later versions.

## Install

```
/plugin install power-setup
/power-setup:install-statusline
```

Then restart Claude Code.

## What it does

`/power-setup:install-statusline` copies one file to your `~/.claude/`:

- `~/.claude/statusline-command.sh` — the status line script
- adds a `statusLine` entry to `~/.claude/settings.json` pointing at that script

It's idempotent. Re-run it any time to pick up updates. Your existing `settings.json` is backed up to `settings.json.bak.<timestamp>` before any write.

The script lives in your home directory when it's done. Edit it — it's yours.

## Read the bash before running it

If you want to eyeball the status line script before installing, it's right here:

- [`statusline/statusline-command.sh`](./statusline/statusline-command.sh)
- [`scripts/install.sh`](./scripts/install.sh)

~100 lines of shell, nothing fancy.

## What you get

A compact two-line status line:

```
Opus  count-tongulas-toolkit  ⌥ power-setup
78% left  $0.42  3m
```

- Model name (Opus / Sonnet / Haiku)
- Project (current directory)
- Git branch — purple `⌥` prefix when you're in a worktree
- Context remaining percentage, colored by headroom
- Session cost (hidden at $0.00)
- Session duration

## Dependencies

- `jq`
- `git`

Installer checks for both and fails loudly with a `brew install` hint if either is missing.

## Uninstall

The script and settings entry live in your `~/.claude/` — delete the `statusLine` block from `settings.json` and remove `~/.claude/statusline-command.sh`. Uninstalling the plugin alone won't touch them (that's by design — your config is yours).
