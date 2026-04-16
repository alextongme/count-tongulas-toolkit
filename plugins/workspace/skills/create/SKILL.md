---
description: "Create a team workspace with shared context across multiple repos"
model: claude-opus-4-6
allowed-tools: ["Bash(gh repo view:*)", "Bash(gh auth status:*)", "Bash(git init:*)", "Bash(chmod +x:*)", "Bash(date:*)", "Bash(command -v:*)", "Bash(mkdir:*)", "Bash(ls:*)"]
---

# Workspace Create Command

Create a new team workspace with repo registry, shared context, and safety defaults.

**CRITICAL: Execute every phase and every step in order. Do NOT skip, combine, or assume defaults for any step — even if you think you know the answer from context. Every AskUserQuestion must be shown to the user.**

## Before You Start

Display this notice:

> **Have you checked with your team?** If your team already has a shared workspace, you should use that instead of creating a new one. Ask in your team's chat or check GitHub for an existing `{team}-workspace` repo.

Use **AskUserQuestion** with options:
- **"Yes, no existing workspace"** -- proceed
- **"Not sure, let me check first"** -- STOP and tell the user to check with their team, then re-run `/workspace:create` when ready

Do NOT proceed until the user confirms.

## Phase 0: Pre-flight Checks

Run prerequisite checks. Use separate Bash calls so you can report ALL missing tools at once:

    Bash: command -v gh && command -v jq && command -v git
    Bash: gh auth status 2>&1

If ANY check fails, STOP and list everything that needs fixing:
- Missing `gh`: "Install GitHub CLI: `brew install gh && gh auth login`"
- Missing `jq`: "Install jq: `brew install jq`"
- Missing `git`: "Install git: `brew install git`"
- `gh` not authenticated: "Authenticate GitHub CLI: `gh auth login`"

Do NOT proceed past Phase 0 until all checks pass.

## Phase 1: Gather Team Information

### 1a. Team Name (required)

Print this as plain text (do NOT use AskUserQuestion — let the user type freely):

"What is your team name? This becomes your workspace folder name (e.g., Platform -> `platform-workspace`)."

Wait for the user's response.

**Sanitize to slug**: lowercase -> spaces to hyphens -> strip characters not in `[a-z0-9-]` -> collapse consecutive hyphens -> strip leading/trailing hyphens.

If the slug is empty after sanitization, ask again.

### 1b. GitHub Naming Conflict Check

Ask the user for their GitHub org name. Default to their `gh` authenticated user if they don't have one.

Check if `{slug}-workspace` already exists:

    Bash: gh repo view {org}/{slug}-workspace --json name 2>&1

- Exit 0 = repo exists. Warn and use **AskUserQuestion**: "Use a different name" or "Continue anyway"
- "not found" or "Could not resolve" = doesn't exist. Proceed silently
- Any other error = prerequisite problem. STOP and tell the user to fix it

### 1c. Project Tracker Prefix (optional)

Ask: "What is your project tracker prefix? (e.g., PAY, PLAT — leave empty to skip)"

If empty, use the literal string `PREFIX` as placeholder in templates.

### 1d. Output Directory

You MUST ask the user where to put the workspace. Do NOT skip this step or assume a default. Use **AskUserQuestion** with this exact question and these exact four options:

Question: "Where should the workspace be created? (`{slug}-workspace` will be created inside your choice)"

Options:
- **"Documents (`~/Documents/`)"**
- **"Desktop (`~/Desktop/`)"**
- **"Home directory (`~/`)"**
- **"Current directory (`{cwd}/`)"**

After receiving the choice, resolve the full output path as `{parent_dir}/{slug}-workspace`. Resolve `~` to the home directory. Resolve relative paths to absolute.

Then confirm using a second **AskUserQuestion**: "Workspace will be created at `{absolute_path}`. Is this correct?"
- **"Yes, use this location"** -- proceed
- **"No, let me pick a different path"** -- go back and re-ask

**If the directory already exists:**
1. Warn: "Directory already exists. Generated files will be replaced."
2. If `.claude/CLAUDE.md` exists, note it will be backed up.
3. Use **AskUserQuestion**: "Continue and overwrite" or "Use a different path"
4. If confirmed and CLAUDE.md exists, back it up to `.claude/CLAUDE.md.bak`

### 1e. Repo List

End Phase 1 by printing this message as plain text. **Do not call AskUserQuestion or any other tool after printing this message.** Claude Code will display your text and wait for the user's next message.

> Enter all your repos in one message — comma-separated, space-separated, or one per line all work. Any format:
> - Just the repo name (e.g., `payments-api`)
> - `org/payments-api`
> - GitHub URL (e.g., `https://github.com/org/payments-api`)
> - SSH URL (e.g., `git@github.com:org/payments-api.git`)
>
> Example: `payments-api, checkout-frontend, billing-service`

## Phase 2: Parse Repositories

The user's message contains their complete repo list. Parse all identifiers in a single pass.

**If the message is clearly not a repo list** (a question, request to go back, etc.), respond appropriately and re-print the 1e prompt when ready.

**Otherwise, parse as repos.** Do not call AskUserQuestion. Do not ask for more repos or confirmation. Treat the message as final and proceed to Phase 3.

**Split:** Split on newlines. For each line, strip leading whitespace, markdown bullets (`- `, `* `), and numbering (`\d+\. ` prefix). Then split each line on commas. Then split each segment on whitespace. Process each resulting token individually.

**Normalize:** Strip `https://github.com/`, `http://github.com/`, `ssh://git@github.com/`, or `git@github.com:` prefixes. Strip `.git` suffix. Take only the first two `/`-separated segments. **If a token has no `/` (bare repo name), ask the user for their default GitHub org** (only once, then reuse for all bare names).

**Validate:** Must match `^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$`. Skip invalid tokens silently -- prose fragments and descriptions naturally become invalid after splitting and are harmless.

**Duplicate detection:** Extract basename (after `/`). If already seen, skip and note: "Duplicate: `{name}` -- repos can't share a short name (they'd collide on disk)."

**Minimum:** At least 1 valid repo required. If none found, show format examples and re-print the 1e prompt (plain text, no tool calls).

**Summary:** Print a brief summary (e.g., "Parsed 5 repos: payments-api, checkout-frontend, billing-service, config, deploy-tools"). Proceed directly to Phase 3.

## Phase 3: Fetch GitHub Metadata

For each repo, run a Bash command:

    Bash: gh repo view {org/repo} --json description,primaryLanguage,defaultBranchRef

Run all repos in parallel using multiple Bash tool calls in a single message. If more than 15 repos, batch into groups of 15.

Extract from each result:
- `description` (fallback: "No description" if null/empty)
- `primaryLanguage.name` (fallback: "unknown" if null)
- `defaultBranchRef.name` (fallback: "main" if null)

**If `gh repo view` fails for a repo** (404, no access, typo), do NOT silently continue. Immediately surface it to the user using **AskUserQuestion**:

> Could not find `{org/repo}` on GitHub. This could be a typo, a private repo you don't have access to, or the repo may not exist.

Options:
- **"Re-enter this repo"** -- ask the user for the correct name, normalize and validate it, then retry the `gh repo view` call
- **"Remove it from the list"** -- drop this repo and continue with the rest
- **"Keep it anyway"** -- proceed with placeholder metadata (description="TODO", language="unknown", defaultBranch="main")

If the user re-enters and the new name also fails, repeat the prompt. Track any repos kept with placeholder metadata to report at the end.

## Phase 4: Group Repositories

Auto-group repos by primary language. Map the exact `primaryLanguage.name` string from the GitHub API:

| GitHub language | Group | Display name |
|---|---|---|
| `Go` | `go` | Go |
| `TypeScript` | `typescript` | TypeScript |
| `JavaScript` | `typescript` | TypeScript |
| `Python` | `python` | Python |
| `Swift` | `ios` | iOS |
| `Objective-C` | `ios` | iOS |
| `Kotlin` | `android` | Android |
| `Java` | `android` | Android |
| `HCL` | `infra` | Infrastructure |
| Everything else | `other` | Other |

Print the grouping as informational output (e.g., "`go` (2): payments-api, billing-service / `typescript` (1): checkout-frontend"). Do not ask for confirmation -- proceed directly. Users can edit `repos.json` later to rearrange groups.

## Checkpoint

Before generating files, display accumulated state:
- Team: {display name} / Slug: {slug}
- Tracker: {prefix or "none"}
- Output: {absolute path}
- Repos: {count} in {group count} groups
- Metadata failures: {list or "none"}

Proceed to file generation.

## Phase 5: Generate repos.json and .gitignore

### repos.json

Build a JSON object. Keys are group names (sorted alphabetically). Values are arrays of repo objects:

```json
{
  "name": "payments-api",
  "repo": "org/payments-api",
  "description": "Payment processing API",
  "language": "Go",
  "defaultBranch": "main"
}
```

Use **Write** to create `{output_dir}/repos.json` with 2-space indentation.

### .gitignore

Use **Write** to create `{output_dir}/.gitignore`:

```
# Cloned repos (auto-generated from repos.json -- run 'make gitignore' to update)
{repo_name_1}/
{repo_name_2}/
...

# OS
.DS_Store

# Dependencies and secrets
node_modules/
.env*

# Claude Code -- ignore local files, track shared config, skills, and agents
.claude/*
!.claude/CLAUDE.md
!.claude/skills/
!.claude/agents/
!.claude/rules/
CLAUDE.local.md
```

Repo entries are ALL basenames across all groups, each with trailing `/`.

## Phase 6: Copy Templates and Generate Dynamic Files

### Resolve template directory

Resolve the plugin root to an absolute path:

    Bash: ls ${CLAUDE_PLUGIN_ROOT}/templates/

If this fails, STOP: "Plugin templates not found. Reinstall the workspace plugin."

Use the resolved absolute directory path for all Read calls below.

### Step 1: Create output directory and read all templates (parallel)

Create the output directory:

    Bash: mkdir -p {output_dir}/.claude/rules

Then issue ALL of these **Read** calls in a single message (parallel):
- **Read** `{templates_dir}/Makefile`
- **Read** `{templates_dir}/setup.sh`
- **Read** `{templates_dir}/CLAUDE.md.template`
- **Read** `{templates_dir}/README.md.template`
- **Read** `{templates_dir}/rules/workspace-scope.md`
- **Read** `${CLAUDE_PLUGIN_ROOT}/skills/create/references/template-substitutions.md`

### Step 2: Apply substitutions

Print before starting: "Generating workspace files — the CLAUDE.md template takes a few minutes."

Using the template contents from Step 1:
- **CLAUDE.md**: Apply all substitutions per the reference file
- **README.md**: Replace `__TEAM_NAME__` -> display name, `__TEAM_SLUG__` -> slug
- **Makefile** and **setup.sh**: Copy as-is

### Step 3: Write all output files (parallel)

Issue ALL of these in a single message. **Do NOT re-write repos.json or .gitignore — they were already written in Phase 5.**

- **Write** `{output_dir}/Makefile`
- **Write** `{output_dir}/setup.sh`
- **Write** `{output_dir}/.claude/CLAUDE.md`
- **Write** `{output_dir}/.claude/rules/workspace-scope.md` (copy as-is from template, no substitutions)
- **Write** `{output_dir}/README.md`

Then: `chmod +x {output_dir}/setup.sh`

## Phase 7: Finalize and Summary

### Git init

If `{output_dir}/.git` already exists, skip.

Otherwise:

    Bash: git init --quiet -b main {output_dir}

### Summary

Display:

```
## Workspace Created!

**Location**: {output_dir}/

### Generated Files
| File | Description |
|------|-------------|
| `repos.json` | {N} repos in {M} groups |
| `.gitignore` | Excludes cloned repos |
| `.claude/CLAUDE.md` | Scaffolded with repo map and deployment table |
| `Makefile` | Workspace commands (setup, update, status, search) |
| `setup.sh` | Bootstrap script (clone, build, plugins) |
| `README.md` | Workspace documentation with prereqs and plugins |

### Next Steps

> **Note:** Commands below may wrap in your terminal. Remove newlines when copying.

1. Switch to your workspace and clone repos:
   `cd {output_dir} && make setup`
   (Optional: edit `repos.json` first to regroup — groups only affect
   how repos are organized in CLAUDE.md, not what gets cloned)

2. Fill in what code scanning can't discover -- the tribal knowledge in `.claude/CLAUDE.md`:
   - **System codenames** -- internal names Claude can't google
   - **Cross-repo relationships** -- which service calls which, deploy order
   - **Gotchas** -- things that have burned your team (include ticket numbers)

3. Commit the scaffold so you have a clean rollback point:
   `git add . && git commit -m "scaffold"`

4. Let Claude scan the cloned code and enrich your CLAUDE.md -- start Claude (`claude`), then type `/init`. After it finishes, exit and review with `git diff`.

5. See all available workspace commands:
   `make help`

6. Publish to GitHub:
   `gh repo create {org}/{slug}-workspace --private --source=. --push`
```

If there were metadata fetch failures from Phase 3, append:
"**Note**: Could not fetch metadata for: {list}. Update descriptions in repos.json manually."

## Error Handling

| Phase | Error | Action |
|-------|-------|--------|
| Pre | User unsure about existing workspace | STOP, tell them to check with team first |
| 0 | Missing tool or auth | STOP, report ALL missing tools at once |
| 1 | Slug empty | Re-ask |
| 1 | Repo already exists on GitHub | Warn, offer rename or continue |
| 1 | Output dir not specified | Always prompt, no silent default |
| 1 | Output dir exists | Warn, ask confirmation, backup CLAUDE.md |
| 2 | Not a repo list | Respond to question, re-print 1e |
| 2 | No valid repos | Show format, re-print 1e |
| 3 | Metadata fetch fails | Prompt user: re-enter, remove, or keep with placeholders |
| 6 | Templates not found | STOP, suggest plugin reinstall |
| 6 | Write failure | Report which file, suggest checking permissions |
| 7 | git init failure | Report error, note files are still usable |
