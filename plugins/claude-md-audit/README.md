# claude-md-audit

Review and score CLAUDE.md and `.claude/rules/` files. Scores signal, flags noise, and suggests improvements based on a rubric of proven best practices.

## Commands

| Command | Description |
|---------|-------------|
| `/claude-md-audit:audit` | Audit all CLAUDE.md and rules files in the current repo |
| `/claude-md-audit:audit <path>` | Audit a specific file |
| `/claude-md-audit:audit hierarchy` | Analyze how all loaded CLAUDE.md files work together across the full resolution stack |

## What It Scores

### Signal (what should be present) — up to +8

| # | Signal | Points |
|---|--------|--------|
| S1 | System names / codenames | +2 |
| S2 | Non-obvious defaults | +2 |
| S3 | Gotchas (hard-won lessons) | +1 or +2 |
| S4 | Behavioral guardrails | +1 |
| S5 | Decision framework | +1 |

### Noise (what should not be present) — up to -9

| # | Anti-Pattern | Points |
|---|-------------|--------|
| N1 | The Novel (too long) | -1 |
| N2 | The Duplicate (derivable content) | -2 |
| N3 | The Wishlist (vague instructions) | -2 |
| N4 | The Stale Doc (outdated references) | -1 |
| N5 | The Settings Leak (JSON config in markdown) | -1 |
| N6 | The Railroader (rigid step-by-step scripts) | -1 |
| N7 | The Template Dump (unedited boilerplate) | -1 |

### Structure — up to +3

| # | Criterion | Points |
|---|-----------|--------|
| T1 | Includes the "why" | +1 |
| T2 | No hierarchy duplication | +1 |
| T3 | Right-sized (30–150 lines) | +1 |

**Score range: -9 to 11.** 9–11 is strong, 5–8 functional, 0–4 needs work, below 0 problematic.

## Hierarchy Mode

`/claude-md-audit:audit hierarchy` checks how files across the full CLAUDE.md resolution stack interact — detecting duplication, conflicts, coverage gaps, misplaced content, and dead weight across global, personal, workspace, repo, and subdirectory levels.

## Example Output

```
### CLAUDE.md

**Score: 7 / 11** (Signal: +5/8 | Noise: -1 | Structure: +3/3)

#### Signal
- [x] S1 System names — "Atlas = internal search engine" (line 12)
- [x] S2 Non-obvious defaults — "pnpm, main branch is develop" (line 3)
- [x] S3 Gotchas (+2) — "MD5 hash breaks with extra query params" (line 34)
- [ ] S4 Behavioral guardrails — MISSING
- [x] S5 Decision framework — "Prioritize: testability > readability" (line 40)

#### Noise Detected
- N3 The Wishlist — "Always write clean, well-tested code" (line 45)

#### Structure
- [x] T1 Includes the "why"
- [x] T2 No hierarchy duplication
- [x] T3 Right-sized — 87 lines

#### Top 3 Recommendations
1. **Add:** Behavioral guardrails — attempt limits or confirmation requirements
2. **Remove:** Line 45 vague instruction — replace with a specific convention
3. **Improve:** S3 gotchas — add ticket references for traceability
```

## Installation

```bash
/install claude-md-audit@count-tongulas-toolkit
```
