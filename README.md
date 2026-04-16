# Count Tongula's Toolkit

Free Claude Code plugins from [Alex Tong](https://alextong.me) — skills, templates, and configs for AI-assisted development. Each plugin comes with a full walkthrough on [alextong.me/newsletter](https://alextong.me/newsletter).

## Install

Add the marketplace once:

```
/plugin marketplace add alextongme/count-tongulas-toolkit
```

Then install any plugin:

```
/plugin install count-tongulas-workspace@count-tongulas-toolkit
/plugin install pr@count-tongulas-toolkit
/plugin install education@count-tongulas-toolkit
/plugin install claude-brain@count-tongulas-toolkit
```

## Plugins

| Plugin | What it does | Walkthrough |
|--------|--------------|-------------|
| `count-tongulas-workspace` | Creates multi-repo workspaces with shared Claude context — generates a repo registry, CLAUDE.md scaffold, Makefile, and bootstrap script. | [alextong.me/toolkit/workspace](https://alextong.me/toolkit/workspace) |
| `pr` | Generates structured PR descriptions from the current branch diff. Built for AI-assisted development where the PR body is the primary review artifact. | [The PR Description Is the New Code Review](https://alextong.me/newsletter/code-review-wrong) |
| `education` | Creates beautiful, printable educational worksheets as self-contained HTML files. For any grade level, subject, or audience. | [alextong.me/toolkit](https://alextong.me/toolkit) |
| `claude-brain` | Audits CLAUDE.md and `.claude/rules/` files for staleness, contradictions, and missing context. | [alextong.me/toolkit](https://alextong.me/toolkit) |

## Why a marketplace?

One install command, one update path, one place for issues. Raw `SKILL.md` files still live on [alextong.me/toolkit](https://alextong.me/toolkit) for anyone who wants to copy-paste instead of install.

## Contributing

Issues and PRs welcome. Every plugin must:

1. Have YAML frontmatter with `name: alextongme:<plugin>` and a trigger-loaded description including negative examples.
2. Include the standardized byline under the H1: `> From [Count Tongula's Toolkit](https://alextong.me/toolkit) by [Alex Tong](https://alextong.me) — more at [alextong.me/newsletter](https://alextong.me/newsletter)`
3. Follow the Anthropic skill spec: Overview, Quick Reference, Requirements for Outputs, phased Process, worked Example, edge cases.
4. Pass CI validation (`.github/workflows/validate.yml`).

## Install telemetry

`/plugin marketplace add` does a `git clone` under the hood, so GitHub's traffic API is a zero-code proxy for installs. To check:

```bash
bash scripts/stats.sh
```

Reports clones (14-day rolling window), top referrers, and top paths. Requires `gh` CLI authenticated with traffic read permission (repo admin).

## License

MIT — see [LICENSE](./LICENSE).
