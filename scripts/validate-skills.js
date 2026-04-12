#!/usr/bin/env node
// Validates every SKILL.md under plugins/ against the toolkit's gold spec:
// - YAML frontmatter with alextongme: namespaced name
// - description includes trigger list + "Do NOT use for:" negatives
// - body contains the standardized byline + all required gold-spec sections

const fs = require("fs");
const path = require("path");

const REQUIRED_SECTIONS = [
  "## Overview",
  "## Quick Reference",
  "## Requirements for Outputs",
  "## Process",
  "## Example",
];

function fail(msg) {
  console.error("FAIL: " + msg);
  process.exit(1);
}

function walk(dir, out) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(p, out);
    } else if (entry.name === "SKILL.md") {
      out.push(p);
    }
  }
  return out;
}

const skills = walk("plugins", []);
if (skills.length === 0) fail("no SKILL.md files found under plugins/");

for (const file of skills) {
  const content = fs.readFileSync(file, "utf8");

  if (!content.startsWith("---\n")) {
    fail("missing YAML frontmatter: " + file);
  }

  const end = content.indexOf("\n---", 4);
  if (end === -1) fail("unclosed frontmatter: " + file);

  const frontmatter = content.slice(4, end);
  const body = content.slice(end + 4);

  if (!/^name:\s*alextongme:/m.test(frontmatter)) {
    fail("frontmatter name must start with 'alextongme:' in " + file);
  }
  if (!/^description:/m.test(frontmatter)) {
    fail("frontmatter missing 'description' in " + file);
  }
  if (!/Do NOT use for:/i.test(frontmatter)) {
    fail("description must include 'Do NOT use for:' negatives in " + file);
  }

  if (!body.includes("Count Tongula's Toolkit")) {
    fail("SKILL.md missing toolkit byline: " + file);
  }

  for (const section of REQUIRED_SECTIONS) {
    if (!body.includes(section)) {
      fail("SKILL.md missing section '" + section + "': " + file);
    }
  }
}

console.log("OK: " + skills.length + " skills validated");
