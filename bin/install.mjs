#!/usr/bin/env node

import { existsSync, mkdirSync, cpSync, rmSync } from "fs";
import { join } from "path";
import { homedir } from "os";
import { fileURLToPath } from "url";
import { dirname } from "path";
import { createInterface } from "readline";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const source = join(__dirname, "..", "aegis");

console.log("");
console.log("  Aegis — Secure Software Design Documents");
console.log("  =========================================");
console.log("");

// Check source exists
if (!existsSync(source)) {
  console.error("  Error: aegis/ directory not found in package.");
  process.exit(1);
}

// Parse flags
const args = process.argv.slice(2);
let scope = null;

if (args.includes("--global") || args.includes("-g")) {
  scope = "global";
} else if (args.includes("--local") || args.includes("-l")) {
  scope = "local";
}

// Ask if no flag provided
if (!scope) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = await new Promise((resolve) => {
    console.log("  Where do you want to install Aegis?");
    console.log("");
    console.log("    g) Global  — available in all projects (~/.claude/plugins/aegis/)");
    console.log("    l) Local   — this project only (.claude/plugins/aegis/)");
    console.log("");
    rl.question("  Choose [g/l]: ", resolve);
  });
  rl.close();

  const choice = answer.trim().toLowerCase();
  if (choice === "l" || choice === "local") {
    scope = "local";
  } else {
    scope = "global";
  }
  console.log("");
}

// Determine target
let target;
if (scope === "local") {
  target = join(process.cwd(), ".claude", "plugins", "aegis");
} else {
  const claudeDir = join(homedir(), ".claude");
  if (!existsSync(claudeDir)) {
    console.error("  Error: ~/.claude not found. Is Claude Code installed?");
    console.error("  Install Claude Code first: https://claude.ai/claude-code");
    process.exit(1);
  }
  target = join(homedir(), ".claude", "plugins", "aegis");
}

// Create parent dirs if needed
const parentDir = dirname(target);
if (!existsSync(parentDir)) {
  mkdirSync(parentDir, { recursive: true });
}

// Remove old installation at this scope
if (existsSync(target)) {
  rmSync(target, { recursive: true });
  console.log("  Removed previous Aegis installation.");
}

// Copy
cpSync(source, target, { recursive: true });

const scopeLabel = scope === "local" ? "project" : "global";
console.log(`  Installed (${scopeLabel}): ${target}`);
console.log("");
console.log("  Usage:");
console.log("    1. Start a new Claude Code session");
console.log("    2. Run /aegis init in your project");
console.log("    3. Follow the guided flow:");
console.log("       /aegis requirements → /aegis design → /aegis tasks → /aegis tests");
console.log("");
console.log("  Commands:");
console.log("    /aegis init          Set up Aegis in your project");
console.log("    /aegis requirements  Generate requirements.md");
console.log("    /aegis design        Generate design.md");
console.log("    /aegis tasks         Generate tasks.md");
console.log("    /aegis tests         Generate tests.md + RED test files");
console.log("    /aegis validate      Full validation report");
console.log("    /aegis update        Update artifacts + propagate changes");
console.log("    /aegis status        Show current state");
console.log("");
console.log("  Tip: use npx aegis-sdd --global or npx aegis-sdd --local to skip the prompt.");
console.log("");
console.log("  Done! Restart Claude Code to activate.");
console.log("");
