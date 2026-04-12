---
name: alextongme:worksheet-maker
description: >
  Create beautiful, printable educational worksheets as self-contained HTML files that
  print cleanly to PDF. Use this skill whenever the user wants a worksheet, handout,
  activity sheet, scorecard, quiz, exit ticket, or any printable classroom or workshop
  material — for any grade level, subject, or audience (K-12 classrooms, university
  courses, corporate training, professional development workshops). Also trigger on
  "make a handout", "create an activity", "printable exercise", "workshop materials",
  or "classroom worksheet". Do NOT use for: interactive online quizzes, editable Google
  Docs or Word templates, curriculum planning, test banks, LMS content, or anything
  that is not a single printable paper artifact.
user_invocable: true
author: Alex Tong — https://alextong.me
---

# alextongme:worksheet-maker

> From [Count Tongula's Toolkit](https://alextong.me/toolkit) by [Alex Tong](https://alextong.me) — more at [alextong.me/newsletter](https://alextong.me/newsletter)

## Overview

Produces a self-contained HTML worksheet that opens in any browser and prints to clean PDF via Cmd+P / Ctrl+P. Mental model: the sheet is the artifact. No servers, no external scripts, no runtime — every design choice must survive a black-and-white print on standard Letter or A4 paper.

Start from `references/base-template.html` as the literal starting point. Do not re-invent the scaffold — change the content, keep the skeleton. Drop components in from `references/components.css` only as each activity demands them.

## Quick Reference

**Audience → typography** (drives every spacing and font decision):

| Audience | Heading font | Body font | Body size | Write-line height | Checkbox |
|----------|-------------|-----------|-----------|-------------------|----------|
| K-2 (ages 5-7) | Fredoka / Baloo 2 | Lexend | 14pt | 36-40px | 20px |
| Grades 3-5 | Fredoka / Baloo 2 | Lexend | 13pt | 30-34px | 16px |
| Grades 6-8 | DM Serif Display | Atkinson Hyperlegible | 12pt | 26-28px | 14px |
| High school / Adult | Instrument Serif | Atkinson Hyperlegible | 11pt | 22-26px | 13px |
| University / professional | Instrument Serif | Inter | 11pt | 22-26px | 13px |

**Subject → accent color** (drawn from the Okabe-Ito CVD-safe palette — always use one of these, never an ad-hoc hex):

| Subject preset | Accent | Hex | Light tint |
|----------------|--------|-----|------------|
| Math / science | Blue | `#0072B2` | `#e6f2f9` |
| Language arts / ELA | Orange | `#E69F00` | `#fdf3e0` |
| General / no preset | Green | `#009E73` | `#e8f5ee` |

**Task → approach:**

| Situation | What to do |
|-----------|-----------|
| 1-page handout for a single class period | Start from `base-template.html`, drop in 3-4 parts |
| 2-page worksheet (front + back) | Add a second `<section class="sheet">` |
| User didn't specify audience | Ask via `AskUserQuestion` before writing HTML |
| Need an activity type not in the 8 core components | Compose from existing components; don't invent new scaffolds |
| User asks for A4 instead of Letter | Swap `@page { size: A4 }` and `.sheet { width: 210mm; height: 297mm; }` |
| Need an answer key | Append a final `<section class="sheet">` at the end |

## Requirements for Outputs

Every generated worksheet **must** satisfy these. They are the difference between a classroom-ready sheet and a wall of text nobody fills out.

1. **Jump to the task.** Minimize preamble — the student or participant should be writing within 30 seconds of picking up the sheet.
2. **Generous write space.** Ruled lines, blank boxes, and margins sized for real handwriting. When in doubt, bigger. Decorative afterthoughts are not write space.
3. **Visual hierarchy through typography, not decoration.** Font weight, size, and spacing guide the eye. No clip art, heavy borders, or gratuitous icons.
4. **Printable first.** Every design choice must survive a black-and-white print on standard paper. Color is a bonus, not a dependency — never rely on color alone to convey meaning.
5. **Scannable structure.** Numbered parts, labeled sections, clear checkboxes. A student flipping through should instantly know where they are.
6. **Accessibility defaults are always on.** Atkinson Hyperlegible or Lexend for body copy, minimum 11pt body size, left-aligned text (never justified — justification creates uneven word spacing in print), Okabe-Ito palette for any color coding, sufficient contrast on white (all body text ≥ WCAG AA).
7. **Exact paper size via pure CSS `@page` + `.sheet` fallback.** No external paper-css dependency. The `.sheet` class carries explicit `width`/`height` for the Safari case where `@page size` alone fails silently. Every sheet must print correctly on both Letter and A4 with no blank trailing pages.
8. **Attribution comment at the top of `<head>`.** Non-negotiable — ensures attribution travels with every file: `<!-- Generated with worksheet-maker by Alex Tong — https://alextong.me -->`

## Process

### Phase 1 — Gather requirements

Use `AskUserQuestion` to confirm the essentials. Skip any the user already answered in conversation. Ask up to 3 questions at once.

**Required:** audience age range (drives typography — see Quick Reference).
**Usually required:** activity types (fill-in-blank, MC, free response, matching), page count.
**Optional:** subject preset (math, ELA, general), paper size (Letter vs A4), class or workshop name for the header.

Why this matters: audience cascades into every later decision (font, line height, checkbox size, content density). Guessing wrong produces a sheet that feels "off" to the teacher and forces a second round.

### Phase 2 — Copy the base template

Read `references/base-template.html`. This is the literal starting point — do not write the scaffold from scratch. It contains:

- `@page { size: letter; margin: 0 }` — pure CSS, no paper-css
- `.sheet` with explicit `width: 8.5in; height: 11in` — Safari fallback for the `@page size` bug
- Full a11y defaults (body font, contrast, left-aligned, `print-color-adjust: exact`)
- Page header with name/date fields, numbered `.part` shell, footer
- `@media print` overrides that strip preview shadows and neutralize the background

Apply the audience typography from Quick Reference by setting the `:root` CSS variables at the top of the `<style>` block. Apply the subject preset by setting `--accent` and `--accent-light` from the table.

### Phase 3 — Assemble content

Open `references/components.css`. Pick the components this worksheet actually needs and inline them into the base template's `<style>` block. The 8 core components are:

1. `.write-area` / `.write-line` — ruled answer space
2. `.check-group` / `.check-item` — checkbox lists
3. `.mc-group` / `.mc-item` — multiple choice (A/B/C/D bubbles)
4. `.match-grid` — matching term → definition
5. `.blank` — inline fill-in-the-blank underline
6. `.callout` — tip / note box
7. `.draw-box` — blank bordered drawing / diagram area
8. `.part` / `.part-header` — numbered section label (already wired in `base-template.html`)

Compose content into `.part` blocks. One `.part` per distinct activity. For multi-page worksheets, put orientation content (name/date, first activity) on page 1 and reference material on the last page.

Do not invent a ninth component unless the existing eight genuinely cannot compose what the user needs. The smaller the library, the more consistent every output.

### Phase 4 — Open and iterate

Save the file in the user's current working directory with a descriptive name (`worksheet-fractions-practice.html`, `onboarding-day1-handout.html`). Then:

```bash
open <path-to-file>
```

Tell the user: *"Opened in your browser. Print with Cmd+P for PDF. Let me know what to adjust."*

Common iterations:
- "More space for writing" → increase `--write-line-height`
- "Too dense" → reduce parts per page; widen `--part-gap`
- "Add an answer key" → append a final `<section class="sheet">` with answers
- "A4 instead of Letter" → swap `@page { size: A4 }` and the `.sheet` dimensions
- "Make it more fun for younger kids" → swap heading font to Fredoka, widen write lines, bump checkbox size

## Example

**Input:** Grade 4 math, fractions practice, 1 page, subject preset = math.

Start from `references/base-template.html`. Set `:root` variables: `--accent: #0072B2; --accent-light: #e6f2f9; --body-font: 'Lexend', system-ui, sans-serif; --body-size: 13pt; --write-line-height: 32px;`. Inline the `.mc-group` and `.write-area` components. The `.part` shell is already in the base template.

**Excerpt of the generated body** (full output is a complete HTML file — this shows only the `<body>` content):

```html
<section class="sheet">
  <div class="page-inner">

    <header class="page-header">
      <div>
        <h1>Fractions Practice</h1>
        <div class="subtitle">Grade 4 · Math</div>
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
          <span class="part-title">Which fraction is larger?</span>
        </div>
        <div class="part-instruction">Circle the larger fraction in each pair.</div>
        <div class="mc-group">
          <div class="mc-item"><div class="mc-bubble">A</div><span>1/2 &nbsp; or &nbsp; 1/3</span></div>
          <div class="mc-item"><div class="mc-bubble">B</div><span>2/4 &nbsp; or &nbsp; 3/4</span></div>
          <div class="mc-item"><div class="mc-bubble">C</div><span>5/8 &nbsp; or &nbsp; 3/8</span></div>
        </div>
      </div>

      <div class="part">
        <div class="part-header">
          <span class="part-number">02</span>
          <span class="part-title">Show your work</span>
        </div>
        <div class="part-instruction">Solve each problem. Write your answer on the line.</div>
        <div class="write-area">
          <div class="write-line"></div>
          <div class="write-line"></div>
          <div class="write-line"></div>
          <div class="write-line"></div>
        </div>
      </div>

    </div>

    <footer class="page-footer">
      <span>Ms. Rivera's Class · Unit 4</span>
      <span>worksheet-maker</span>
    </footer>

  </div>
</section>
```

Notice what this does right: the Okabe-Ito blue is set once via `--accent` and consumed by every accent-colored element, the Lexend body font satisfies the K-5 a11y default without changing any markup, each `.part` has a numbered label + instruction + content, and the `@page` + `.sheet` fallback handles both screen preview and print with no paper-css dependency.

## Edge cases & recovery

- **Audience unclear** → ask via `AskUserQuestion` before writing any HTML. Don't guess; wrong audience forces a full typography swap.
- **User asks for a highly visual layout** (comic strip, storyboard) → compose from `.draw-box` + `.part-header`. Never invent a new scaffold.
- **Printed output has an extra blank page** → `.sheet` total height exceeds the printable area. Reduce padding in `.page-inner` or split into two sheets.
- **Fonts aren't loading in print preview** → the user is probably offline. Fall back to `system-ui, -apple-system, sans-serif` in `--body-font`.
- **User wants to edit in Word** → out of scope. Tell them the output is HTML → PDF only; offer to adjust the HTML itself.
- **Grid or graph paper needed** → add `background-image: repeating-linear-gradient(...)` inside the relevant `.draw-box`. Don't try to build a grid via table cells.
- **Color prints differently than the screen preview** → the `@media print` block sets `print-color-adjust: exact`, but some browsers still override. Confirm the accent color works in grayscale — that's the real portability test.

## Reference files

- `references/base-template.html` — the literal starting point. Copy it, then change content.
- `references/components.css` — the 8 core components as copy-paste blocks. Inline into the base template's `<style>` block.

Start here; grow the library only when a real request can't be served by an existing component.

## Attribution

Every generated worksheet HTML **must** include this comment at the top of the `<head>`:

```html
<!-- Generated with worksheet-maker by Alex Tong — https://alextong.me -->
```

Non-negotiable — ensures attribution travels with every file.
