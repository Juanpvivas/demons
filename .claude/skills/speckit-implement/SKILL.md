---
name: speckit-implement
description: Compatibility guard for the retired Spec Kit implementation command;
  routes requests to the project agents without executing work.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:demons-agent-tdd
argument-hint: Feature identifier to hand off to the project orchestrator
user-invocable: true
disable-model-invocation: false
---

# Speckit Implement Skill

# Compatibility guard

This repository uses Spec Kit only to prepare specifications, plans, tasks, and
supporting documents. Implementation, tests, and independent validation belong
to the project agents. Read `docs/DEVELOPMENT_WORKFLOW.md` (relative to the repository root)
and `AGENTS.md` for the supported flow.

If this legacy command is requested, explain that it no longer executes tasks
in this project and identify the supported entry point:

- Claude Code: `/implementar-feature <feature-id>`.
- Other tools: the equivalent `project-orchestrator` using the project role
  instructions and the shared workflow.

Only return this compatibility notice and handoff information. Do not invoke
that entry point, run prerequisite scripts or hooks, start agents, edit any
files, implement code, create or run tests, change branches, create Issues or
PRs, or mark tasks complete. A supplied feature identifier is context for the
handoff, not authorization to execute this legacy command.
