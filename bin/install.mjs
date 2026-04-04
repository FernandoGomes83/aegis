#!/usr/bin/env node

import { existsSync, mkdirSync, cpSync, rmSync } from "fs";
import { join } from "path";
import { homedir } from "os";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const source = join(__dirname, "..", "aegis");
const pluginsDir = join(homedir(), ".claude", "plugins");
const target = join(pluginsDir, "aegis");

console.log("");
console.log("  Aegis — Secure Software Design Documents");
console.log("  =========================================");
console.log("");

// Check source exists
if (!existsSync(source)) {
  console.error("  Error: aegis/ directory not found in package.");
  process.exit(1);
}

// Check ~/.claude exists
const claudeDir = join(homedir(), ".claude");
if (!existsSync(claudeDir)) {
  console.error("  Error: ~/.claude not found. Is Claude Code installed?");
  console.error("  Install Claude Code first: https://claude.ai/claude-code");
  process.exit(1);
}

// Create plugins dir if needed
if (!existsSync(pluginsDir)) {
  mkdirSync(pluginsDir, { recursive: true });
}

// Remove old installation
if (existsSync(target)) {
  rmSync(target, { recursive: true });
  console.log("  Removed previous Aegis installation.");
}

// Copy aegis/ to ~/.claude/plugins/aegis/
cpSync(source, target, { recursive: true });

console.log(`  Installed to: ${target}`);
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
console.log("  Done! Restart Claude Code to activate.");
console.log("");
