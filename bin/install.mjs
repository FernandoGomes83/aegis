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
    console.log("    g) Global  — available in all projects (~/.claude/)");
    console.log("    l) Local   — this project only (.claude/)");
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

// Determine base .claude directory
let claudeBase;
if (scope === "local") {
  claudeBase = join(process.cwd(), ".claude");
} else {
  claudeBase = join(homedir(), ".claude");
  if (!existsSync(claudeBase)) {
    console.error("  Error: ~/.claude not found. Is Claude Code installed?");
    console.error("  Install Claude Code first: https://claude.ai/claude-code");
    process.exit(1);
  }
}

const commandsDir = join(claudeBase, "commands");
const frameworkDir = join(claudeBase, "aegis");

// Sub-commands that get installed as aegis:<name>.md
const subCommands = [
  "init",
  "requirements",
  "design",
  "tasks",
  "tests",
  "validate",
  "update",
  "status",
];

// Create commands directory if needed
mkdirSync(commandsDir, { recursive: true });

// Remove previous installation
if (existsSync(frameworkDir)) {
  rmSync(frameworkDir, { recursive: true });
}
// Remove old monolithic command file and colon-prefixed files
for (const file of ["aegis.md", ...subCommands.map((c) => `aegis:${c}.md`)]) {
  const fp = join(commandsDir, file);
  if (existsSync(fp)) rmSync(fp);
}

// Remove old plugins-based installation if present
const oldPluginsDir = join(claudeBase, "plugins", "aegis");
if (existsSync(oldPluginsDir)) {
  rmSync(oldPluginsDir, { recursive: true });
  console.log("  Removed old installation from plugins/aegis/.");
}

// Install command files
// Index file: /aegis
cpSync(join(source, "skill.md"), join(commandsDir, "aegis.md"));
// Sub-commands: /aegis:<name>
for (const cmd of subCommands) {
  cpSync(
    join(source, "commands", `${cmd}.md`),
    join(commandsDir, `aegis:${cmd}.md`)
  );
}

// Install framework + shared + agents (no longer install commands/ to aegis/)
mkdirSync(frameworkDir, { recursive: true });
for (const dir of ["framework", "shared", "agents"]) {
  const src = join(source, dir);
  if (existsSync(src)) {
    cpSync(src, join(frameworkDir, dir), { recursive: true });
  }
}

const scopeLabel = scope === "local" ? "project" : "global";
console.log(`  Installed (${scopeLabel}):`);
console.log(`    Commands:  ${commandsDir}/aegis*.md (${subCommands.length + 1} files)`);
console.log(`    Framework: ${frameworkDir}/`);
console.log("");
console.log("  Usage:");
console.log("    1. Start a new Claude Code session");
console.log("    2. Run /aegis:init in your project");
console.log("    3. Follow the guided flow:");
console.log("       /aegis:requirements → /aegis:design → /aegis:tasks → /aegis:tests");
console.log("");
console.log("  Commands:");
console.log("    /aegis:init          Set up Aegis in your project");
console.log("    /aegis:requirements  Generate requirements.md");
console.log("    /aegis:design        Generate design.md");
console.log("    /aegis:tasks         Generate tasks.md");
console.log("    /aegis:tests         Generate tests.md + RED test files");
console.log("    /aegis:validate      Full validation report");
console.log("    /aegis:update        Update artifacts + propagate changes");
console.log("    /aegis:status        Show current state");
console.log("");
console.log("  Tip: use npx aegis-sdd --global or npx aegis-sdd --local to skip the prompt.");
console.log("");
console.log("  Done! Restart Claude Code to activate.");
console.log("");
