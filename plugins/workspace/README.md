# workspace

Team workspace generator for Claude Code. Creates multi-repo workspaces with shared context, repo registry, and safety defaults.

## Prerequisites

- `gh` (GitHub CLI, authenticated)
- `git`
- `jq`

## Commands

| Command | Description |
|---------|-------------|
| `/workspace:create` | Create a new team workspace |

## What Gets Generated

Running `/workspace:create` produces a workspace directory with:

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
/workspace:create
```

The command walks you through:

1. Team name and project tracker prefix
2. Adding repos (supports org/repo, full URLs, SSH URLs)
3. Auto-grouping by language (or manual grouping)
4. Generates all workspace files
5. Initializes a git repo

After creation, run `make setup` in the new workspace to clone all repos.

## Installation

```bash
/install workspace@count-tongulas-toolkit
```
