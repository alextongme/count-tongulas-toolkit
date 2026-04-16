# count-tongulas-workspace

Multi-repo workspace generator for Claude Code. Creates workspaces with shared context, repo registry, and safety defaults — for teams or personal projects.

## Prerequisites

- `gh` (GitHub CLI, authenticated)
- `git`
- `jq`

## Commands

| Command | Description |
|---------|-------------|
| `/count-tongulas-workspace:create` | Create a new workspace |

## What Gets Generated

Running `/count-tongulas-workspace:create` produces a workspace directory with:

| File | Description |
|------|-------------|
| `repos.json` | Repo registry grouped by language |
| `.gitignore` | Excludes cloned repos, tracks `.claude/` config |
| `.claude/CLAUDE.md` | AI context scaffolded with repo map, deployment table, and guidance |
| `Makefile` | Workspace commands: `setup`, `update`, `status`, `search`, `gitignore` |
| `setup.sh` | Idempotent repo cloning and bootstrap script |
| `README.md` | Workspace documentation |

## Usage

```
/count-tongulas-workspace:create
```

The command walks you through:

1. Choose team or personal mode
2. Workspace name and (team mode) project tracker prefix
3. Adding repos (supports user/repo, org/repo, full URLs, SSH URLs)
4. Auto-grouping by language via GitHub API
5. Generates all workspace files
6. Initializes a git repo

After creation, run `make setup` in the new workspace to clone all repos.

## Installation

```bash
/plugin install count-tongulas-workspace@count-tongulas-toolkit
```
