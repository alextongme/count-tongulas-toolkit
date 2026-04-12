---
name: alextongme:worksheet-maker
description: >
  Create beautiful, single-file printable HTML worksheets, handouts, practice
  sheets, study guides, cheat sheets, lab sheets, exercise sheets, or activity
  sheets that print cleanly to PDF via Cmd+P. Primary use case: teaching
  software engineering and technical concepts (git, SQL, async/await,
  Kubernetes, regex, system design, code review, APIs, databases) to engineers,
  bootcamp students, conference workshop attendees, or teammates — but also
  works for K-12 classrooms, university courses, and corporate training across
  any subject. Use this skill whenever the user mentions a worksheet, handout,
  practice sheet, study guide, cheat sheet, printable exercise, lab sheet,
  workshop handout, tech onboarding worksheet, engineering handout, code
  exercise sheet, activity sheet, scorecard, or exit ticket — or asks for a
  paper artifact to teach a concept. Also trigger on "make a handout for
  teaching X", "printable practice for Y", "one-pager for Z", "exercise sheet",
  or "workshop materials". Do NOT use for: interactive web quizzes, editable
  Google Docs / Word / Notion templates, slide decks, LMS modules, curriculum
  plans, test banks, blog posts, or anything that is not a single printable
  paper artifact.
user_invocable: true
author: Alex Tong — https://alextong.me
---

# alextongme:worksheet-maker

> From [Count Tongula's Toolkit](https://alextong.me/toolkit) by [Alex Tong](https://alextong.me) — more at [alextong.me/newsletter](https://alextong.me/newsletter)

## Overview

Produces a self-contained HTML worksheet that opens in any browser and prints to clean PDF via Cmd+P / Ctrl+P. Mental model: the sheet is the artifact. No servers, no runtime, no external scripts — every design choice must survive a black-and-white print on standard Letter or A4 paper.

**Before writing any HTML, read both reference files.** They are not optional — the base template encodes a non-obvious print contract (Safari `.sheet` fallback, element-level `print-color-adjust`, WCAG-compliant ink palette) that is easy to regress if you rewrite the scaffold from scratch.

- `references/base-template.html` — literal starting point. Copy it, change the content, keep the skeleton.
- `references/components.css` — the core components with the exact HTML markup each one expects. Drop them in only as an activity demands.

## Quick Reference

**Audience → typography.** Ask the user for the audience first; this cascades into every font, size, and spacing decision. Rows are in ascending age/seniority. For tech-teaching, match the *role*, not the age.

| Audience | Heading font | Body font | Code font | Body size | Write-line height |
|---|---|---|---|---|---|
| K-2 (ages 5-7) | Fredoka / Baloo 2 | Lexend | — | 14pt | 36-40px |
| Grades 3-5 | Fredoka / Baloo 2 | Lexend | — | 13pt | 30-34px |
| Grades 6-8 | DM Serif Display | Atkinson Hyperlegible | — | 12pt | 26-28px |
| High school / Adult | Instrument Serif | Atkinson Hyperlegible | — | 11pt | 22-26px |
| University | Instrument Serif | Inter | JetBrains Mono | 11pt | 22-26px |
| **Bootcamp / junior dev** | Instrument Serif | Atkinson Hyperlegible | **JetBrains Mono** | 11pt | 24-28px |
| **Mid-senior IC / workshop** | Instrument Serif | Inter | **JetBrains Mono** | 11pt | 22-26px |
| **Conference talk handout** | Instrument Serif | Inter | **JetBrains Mono** | 10.5pt | 20-24px |

> For corporate or professional learners, default to one of the bold rows regardless of age. "Audience" means *context and role*, not just grade band.

**Subject → accent color.** Always pick one from the Okabe-Ito CVD-safe palette — never invent a hex. Any subject not listed uses the green default.

| Subject preset | Accent | Hex | Light tint |
|---|---|---|---|
| Math / science | Blue | `#0072B2` | `#e6f2f9` |
| Language arts / ELA | Orange | `#E69F00` | `#fdf3e0` |
| **Code / systems / engineering** | **Vermillion** | **`#D55E00`** | **`#fbe9df`** |
| Anything else | Green | `#009E73` | `#e8f5ee` |

**Task → approach.**

| Situation | What to do |
|---|---|
| 1-page handout for one class or session | Copy `base-template.html`, drop in 3-4 `.part` blocks |
| 2-page worksheet (front + back) | Append a second `<section class="sheet">` |
| Teaching a code concept | Use `.code-block` + `.predict-table` + `.write-area` for tracing |
| Audience unspecified | Ask via `AskUserQuestion` before writing any HTML |
| Activity type not in the components | Compose from existing components; don't invent new scaffolds |
| A4 instead of Letter | Swap **both** `@page { size: A4 }` **and** `.sheet { width: 210mm; height: 297mm }` — one without the other silently fails in Safari |
| Answer key | Append a final `<section class="sheet">` at the end with a distinct header |

## Requirements for Outputs

Every generated worksheet must satisfy these. They are the difference between a sheet that gets used and a wall of text nobody fills out.

1. **Jump to the task.** Minimize preamble — the reader should be writing within 30 seconds of picking up the sheet.
2. **Generous write space.** Ruled lines, blank boxes, and margins sized for real handwriting or real code-tracing. When in doubt, bigger.
3. **Hierarchy through typography, not decoration.** Font weight, size, and spacing guide the eye. No clip art, heavy borders, or gratuitous icons.
4. **Survives grayscale.** Every design choice must read clearly in black-and-white. Color is a bonus, never a dependency. For diff hunks, use the `+`/`-` prefixes in `.code-add` / `.code-del` — they carry the meaning even when the tint drops out.
5. **Scannable structure.** Numbered `.part` blocks, labeled sections, clear write-lines. A reader flipping through should instantly know where they are.
6. **Accessibility defaults are always on.** Atkinson Hyperlegible / Lexend / Inter for body copy; 11pt minimum body (10.5pt allowed only for conference handouts); left-aligned (never justified — justification creates uneven spacing in print); Okabe-Ito palette for any color coding; WCAG AA contrast (body text on white ≥ 4.5:1).
7. **Exact paper size via pure `@page` + `.sheet` fallback.** No external paper-css dependency, no CDN stylesheets. The `.sheet` class carries explicit `width`/`height` for the Safari case where `@page size` alone fails silently ([MDN #28626](https://bugzilla.mozilla.org/show_bug.cgi?id=28626)).
8. **Attribution comment at the top of `<head>`:** `<!-- Generated with worksheet-maker by Alex Tong — https://alextong.me -->` — non-negotiable; ensures attribution travels with every file.

## Process

### Phase 1 — Gather requirements

Use `AskUserQuestion` to confirm the essentials. Skip any the user already answered in conversation. Ask up to 3 questions at once.

**Required:** audience — age range *or* role/context. Examples: "Grade 4", "bootcamp cohort", "L5 engineers at a design review", "first-time conference attendees". Audience drives every typography decision; guessing wrong forces a full rewrite.

**Usually required:** topic and activity types (fill-in-blank, MC, free response, matching, code-tracing, predict-the-output), page count.

**Optional:** subject preset, paper size (Letter vs A4), header label (class name, workshop name, team name).

### Phase 2 — Copy the base template

Read `references/base-template.html` and copy it as the literal starting point — do not write the scaffold from scratch. It encodes the print contract, which is the hardest part to get right.

Apply the audience typography by setting the `:root` CSS variables at the top of the `<style>` block and updating the Google Fonts `<link>` tag. **Both the variables and the link must match** — swapping one without the other silently falls back to Atkinson.

Apply the subject preset by setting `--accent` and `--accent-light` from the Quick Reference table.

### Phase 3 — Assemble content

Read `references/components.css`. Pick the components this worksheet actually needs and inline their CSS into the base template's `<style>` block. The core components and when to use each:

1. `.write-area` / `.write-line` — ruled answer space, for any free-response question
2. `.check-group` / `.check-item` / `.check-box` — checkbox lists (note: `.check-box` is the visible empty square; don't omit it)
3. `.mc-group` / `.mc-item` / `.mc-bubble` — multiple choice with A/B/C/D bubbles
4. `.match-grid` — matching term → definition
5. `.blank` — inline fill-in-the-blank underline (inside prose)
6. `.callout` — tip or note box
7. `.draw-box` — blank bordered area for sketches, diagrams, or stack traces
8. `.part` / `.part-header` — numbered section label (already wired in the base template)
9. `.code-block` / `.code-blank` / `.code-add` / `.code-del` — monospace code sample with optional fill-in-the-blank gaps and diff-hunk line prefixes
10. `.predict-table` — two-column "Input → Output" table for predict-the-output drills (pairs naturally with `.code-block`)

Compose content into `.part` blocks. One `.part` per distinct activity. For multi-page worksheets, put orientation content (name/date, first activity) on page 1 and reference material on the last page.

Don't invent an 11th component unless the existing ten genuinely cannot compose what the user needs. The smaller the library, the more consistent every output.

### Phase 4 — Open, print-check, iterate

Save the file in the user's current working directory with a descriptive name (`worksheet-git-rebase.html`, `onboarding-day1-handout.html`, `async-await-practice.html`). Then open it:

```bash
open <path-to-file>      # macOS
xdg-open <path-to-file>  # Linux
start <path-to-file>     # Windows
```

Tell the user the exact print dialog settings they need — the defaults will cut content:

> *"Opened in your browser. To export: Cmd+P → **uncheck 'Headers and footers'** → **enable 'Background graphics'** → Save as PDF. Let me know what to adjust."*

The headers/footers checkbox is what kills most first-time prints — the browser's default date/URL strip eats into the content area. Background graphics is how accent fills and callout tints make it into the PDF.

Common iterations:

- "More space for writing" → increase `--write-line-height`
- "Too dense" → reduce parts per page or widen `--part-gap`
- "Add an answer key" → append a new `<section class="sheet">` with the answers
- "A4 instead of Letter" → swap `@page { size: A4 }` **and** `.sheet { width: 210mm; height: 297mm }`
- "Make it more fun for younger kids" → swap heading font to Fredoka, widen write lines
- "Make the code bigger" → bump `.code-block` `font-size` to 11pt and reduce parts per page

## Example

**User prompt:** *"make me a 1-page practice sheet for teaching async/await in Python to a bootcamp cohort — I want them to predict what a couple of snippets print, then trace a small call order by hand"*

**Phase 1 — gather.** The prompt gives us audience (bootcamp cohort), topic (async/await in Python), activity types (predict-the-output, tracing), and page count (1). We still need to confirm:

> `AskUserQuestion`: "Quick confirms before I generate this:
> 1. Cohort week — early (week 1-2) or late (week 6+)? Affects snippet difficulty.
> 2. Do you want an answer key appended? (second page, separate sheet)
> 3. Class or cohort name for the header — or leave it generic?"

Assume the user says: week 4, no answer key, "Cohort 12 · Async Day".

**Phase 2 — copy and tune.** Copy `base-template.html`. Set `:root`:

```css
--accent: #D55E00;         /* Code/systems preset */
--accent-light: #fbe9df;
--body-font: 'Atkinson Hyperlegible', system-ui, sans-serif;
--heading-font: 'Instrument Serif', Georgia, serif;
--body-size: 11pt;
--write-line-height: 26px;
```

Swap the Google Fonts `<link>` to include Atkinson + Instrument Serif + JetBrains Mono. Leave `@page size: letter` and `.sheet { width: 8.5in; height: 11in }` as-is.

**Phase 3 — assemble.** Inline `.code-block`, `.predict-table`, `.write-area`, and `.callout` from `components.css`. Skip the others.

**Output (full single-file HTML):**

```html
<!-- Generated with worksheet-maker by Alex Tong — https://alextong.me -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Async / Await Practice</title>
  <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif&family=Atkinson+Hyperlegible:wght@400;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --ink: #1a1a1a; --ink-light: #555; --ink-muted: #595959;
      --rule: #d0d0d0; --rule-light: #e8e8e8;
      --accent: #D55E00; --accent-light: #fbe9df; --bg-callout: #f5f5f0;
      --body-font: 'Atkinson Hyperlegible', system-ui, sans-serif;
      --heading-font: 'Instrument Serif', Georgia, serif;
      --body-size: 11pt; --h1-size: 26pt;
      --write-line-height: 26px; --part-gap: 14px;
    }
    @page { size: letter; margin: 0; }
    html, body { margin: 0; padding: 0; }
    body {
      background: #e0e0e0; font-family: var(--body-font); font-size: var(--body-size);
      color: var(--ink); line-height: 1.5; text-align: left;
      -webkit-font-smoothing: antialiased;
    }
    .sheet {
      width: 8.5in; height: 11in; background: white;
      margin: 16px auto; box-shadow: 0 4px 20px rgba(0,0,0,0.12);
    }
    /* ... all base-template styles ... */
    /* Inlined from components.css: .code-block, .predict-table, .write-area, .callout */
    @media print {
      body { background: white; print-color-adjust: exact; -webkit-print-color-adjust: exact; }
      .sheet { margin: 0; box-shadow: none; width: 100%; height: 100%; }
    }
  </style>
</head>
<body>
  <section class="sheet">
    <div class="page-inner">

      <header class="page-header">
        <div>
          <h1>Async / Await Practice</h1>
          <div class="subtitle">Cohort 12 · Async Day</div>
        </div>
        <div class="page-number">Page <span>1</span> of 1</div>
      </header>

      <div class="fields-row">
        <div class="field"><span class="field-label">Name</span><span class="field-line"></span></div>
        <div class="field"><span class="field-label">Date</span><span class="field-line"></span></div>
      </div>

      <div class="content">

        <div class="part">
          <div class="part-header">
            <span class="part-number">01</span>
            <span class="part-title">Predict the output</span>
          </div>
          <div class="part-instruction">For each snippet, write what Python prints. Assume the event loop runs to completion.</div>
          <pre class="code-block"><code>async def greet(name):
    print(f"hi {name}")
    await asyncio.sleep(0)
    print(f"bye {name}")

async def main():
    await asyncio.gather(greet("A"), greet("B"))

asyncio.run(main())</code></pre>
          <table class="predict-table">
            <thead><tr><th>Line</th><th>Output</th></tr></thead>
            <tbody>
              <tr><td>First print in <code>greet("A")</code></td><td></td></tr>
              <tr><td>First print in <code>greet("B")</code></td><td></td></tr>
              <tr><td>Second print in <code>greet("A")</code></td><td></td></tr>
              <tr><td>Second print in <code>greet("B")</code></td><td></td></tr>
            </tbody>
          </table>
        </div>

        <div class="part">
          <div class="part-header">
            <span class="part-number">02</span>
            <span class="part-title">Trace the call order</span>
          </div>
          <div class="part-instruction">Walk through <code>main()</code> below and list each line number in the order it executes. The first one is done for you.</div>
          <pre class="code-block"><code>1  async def fetch(url):
2      print(f"start {url}")
3      await asyncio.sleep(1)
4      print(f"done  {url}")
5
6  async def main():
7      await asyncio.gather(fetch("a"), fetch("b"))</code></pre>
          <div class="callout"><strong>Hint:</strong> <code>asyncio.gather</code> schedules both coroutines before either hits its first <code>await</code>.</div>
          <div class="write-area">
            <div class="write-line">7, 2, </div>
            <div class="write-line"></div>
            <div class="write-line"></div>
            <div class="write-line"></div>
            <div class="write-line"></div>
          </div>
        </div>

      </div>

      <footer class="page-footer">
        <span>Cohort 12 · Async Day</span>
        <span>worksheet-maker</span>
      </footer>

    </div>
  </section>
</body>
</html>
```

**What this demonstrates.** The Vermillion accent comes from the Code/Systems preset, consumed by every accent element (the `.code-block` border, the `.callout` strong, the `.part-header`). The `.code-block` preserves whitespace via `white-space: pre` and prints legibly in grayscale because the tinted background + left-border + monospace font all carry without relying on color. The `.predict-table` and `.write-area` both have generous vertical space for handwriting. The `.callout` gives a hint without doing the exercise for the student. Nothing here would work as a K-12 worksheet — everything here IS the primary use case.

The same shape generalizes to any tech topic: swap the code, swap the part titles, swap the hint. "Teaching SQL joins" → `.code-block` with a query + `.predict-table` with sample rows → row output. "Teaching regex" → `.code-block` with the pattern + `.mc-group` for matches. "Teaching git rebase" → two `.code-block` elements with `.code-add` / `.code-del` lines showing before/after.

## Edge cases & recovery

- **Audience unclear** → ask via `AskUserQuestion` before writing any HTML. Wrong audience forces a full typography rewrite.
- **User asks for a non-printable artifact** (Slides, Docs, interactive quiz, LMS, Notion template) → decline explicitly and offer the HTML → PDF alternative. This skill only produces printable paper artifacts.
- **User asks for a subject outside the presets** (history, music theory, phlebotomy, literature analysis) → use the green default. Never improvise a hex; the Okabe-Ito palette is the only CVD-safe option.
- **Non-English / RTL / CJK content** → out of scope. Atkinson and Lexend have limited non-Latin glyph coverage; RTL needs a full layout mirror. Tell the user and stop.
- **Printed output has an extra blank page** → `.sheet` total height exceeds the printable area. Reduce `.page-inner` padding or split into two sheets.
- **Fonts aren't loading in print preview** → the user is offline or on `file://`. Fall back to `system-ui, -apple-system, sans-serif` for body and `Georgia, serif` for headings; warn the user that code samples will render in the system monospace.
- **Color prints differently than the screen preview** → remind the user to enable "Background graphics" in the print dialog. If still wrong, confirm the accent works in grayscale — that's the portability test.
- **User wants syntax highlighting on code** → pre-bake it as inline `<span class="comment">` tags inside `.code-block`. Never add runtime JS, and never rely on color alone to carry syntactic meaning (italic + color is the minimum).
- **User wants an answer key** → append a second `<section class="sheet">` with a distinct `.subtitle` like "Answer Key". Generate it only when the user explicitly asks; don't assume.
- **Paper-css looks tempting as a fix** → it isn't. Never add a CDN stylesheet, even when Safari print preview looks broken. Debug the `.sheet` width/height first.

## Reference files

- `references/base-template.html` — the literal starting point. Copy it; change content.
- `references/components.css` — the core components with exact HTML markup snippets. Inline the blocks you use into the base template's `<style>` block.

Grow the library only when a real request can't be served by an existing component.
