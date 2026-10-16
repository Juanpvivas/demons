---
name: speckit-taskstoissues
description: Prepare one feature-level GitHub Issue draft from spec, plan, and tasks;
  never queries or creates external Issues or starts implementation.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:demons-agent-tdd
argument-hint: Feature identifier and optional guidance for its Issue draft
user-invocable: true
disable-model-invocation: false
---

# Speckit Taskstoissues Skill

# Prepare the feature Issue draft

This legacy skill name is retained for compatibility. It prepares **one Issue
draft for the feature**, not one Issue per `T###` task. Read
`docs/DEVELOPMENT_WORKFLOW.md` (relative to the repository root) and
`AGENTS.md`; Spec Kit prepares documents and the project orchestrator owns
external Issue tracking during implementation.

## Preparation only

Do not query or create external Issues, call GitHub MCP tools or `gh`, execute
hooks, start agents or implementation, run tests/builds/playtests, change
branches, modify game code/scenes/assets/tests, or mark tasks `[X]`.
Return the draft in the conversation; do not publish it or present it as an
existing Issue. A request to use this legacy skill authorizes draft preparation
only within this project workflow.

## Resolve the feature

Use the identifier explicitly supplied by the person. Otherwise read
`.specify/feature.json` and compare it with `specs/`; ask if the feature is
ambiguous. Read `specs/<feature>/spec.md`, `plan.md`, and `tasks.md`, plus the
constitution and applicable design/architecture references. If a required
artifact is missing, report the missing preparatory step instead of inventing
requirements or querying an external tracker.

## Draft format

Write the title and body in Spanish. Include the feature identifier in the
title so the orchestrator can locate its Issue later. Use these sections:

- **Context**: the problem, intended behavior, and relevant references from the
  feature specification, `docs/SPEC.md`, and `docs/ARCHITECTURE.md`.
- **Work**: high-level phases or user stories derived from the plan and tasks.
  Group the work instead of copying every `T###` task into separate Issues.
  Keep RED/GREEN and QA responsibilities consistent with the shared workflow.
- **Acceptance criteria**: copy the feature's `SC-###` success criteria faithfully
  and include the relevant observable acceptance scenarios without expanding
  scope. Note any missing or ambiguous criterion rather than resolving a design
  decision silently.

Link to the feature's `spec.md`, `plan.md`, and `tasks.md` as the detailed
source of requirements, technical approach, and task tracking. Preserve their
IDs, dependencies, and checkbox states; this skill does not approve work.

## Handoff

Return the proposed title/body and explain that it is a local draft. The
`project-orchestrator` will check for an existing Issue by **feature identifier**,
including open and closed Issues (`gh issue list --state all --search
"<feature-id> in:title"` or equivalent), then reuse or create the feature Issue
when implementing through `/implementar-feature <feature-id>` or the equivalent
orchestrator entry point. Do not perform that lookup, create an Issue, or invoke
the entry point from this skill. Task IDs are scoped to a feature and must not
be used as repository-wide deduplication keys.
