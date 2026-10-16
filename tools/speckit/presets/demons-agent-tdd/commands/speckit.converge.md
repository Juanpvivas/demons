---
description: Prepare a static gap analysis and proposed follow-up tasks for an existing
  feature; does not implement, run tests, or replace agent validation.
---


# Prepare follow-up work

Read `docs/DEVELOPMENT_WORKFLOW.md` (relative to the repository root)
and `AGENTS.md`. This command supports planning only. The project agents own
implementation, tests, and independent validation. It does not invoke agents,
`speckit-implement`, hooks, builds, tests, or playtests; it does not edit game
code, scenes, assets, tests, or mark existing tasks `[X]`.

## Inputs and scope

Use the feature identifier explicitly supplied by the person. Otherwise resolve
`.specify/feature.json` and compare it with `specs/`; ask if the feature is
ambiguous. Read `spec.md`, `plan.md`, and `tasks.md` for that feature, the
constitution, and the applicable project references. If any feature artifact
is missing, identify the preparatory command needed and stop this analysis.

Inspect only source files and existing reports relevant to that documented
scope. Static inspection can identify apparent gaps; it cannot establish
runtime correctness or replace `qa-validator`. Do not treat an old `[X]` as
proof of present behavior, reopen approved tasks, or approve delivery here.

## Gap report

For each apparent gap, provide:

- Its requirement or decision reference (`FR-###`, `SC-###`, `US#/AC#`, plan
  section, or constitution principle).
- Evidence with file and line, distinguishing inspected code from prior reports.
- Classification: missing, partial, contradicts, or unrequested.
- Severity and the concrete remaining work or decision.
- Whether an existing pending task already covers it; avoid duplicate work.

Give constitution conflicts and blocked core behavior highest priority. Surface
unrequested code as a decision for the person, without directing its deletion
or expanding feature scope on your own.

## Proposed tasks and handoff

Present candidate tasks in the conversation before changing `tasks.md`.
Append only when the person has explicitly authorized those additions. Preserve
all existing task IDs, content, order, checkbox states, and approval history.
Use the next unused `T###` IDs and the existing checklist format; no new tags.
Keep new work within the approved feature scope.

For behavior that needs automated coverage, propose a RED test task before its
implementation/GREEN task, with prerequisites that allow the test to fail for
the intended behavior rather than a broken harness. Follow the shared workflow
for independent QA of the RED evidence and later GREEN delivery. Gameplay
coverage required by the constitution is mandatory. Do not invent RED tests
for purely visual, documentation, or setup work without testable behavior.

If no apparent gaps are found, report that limit of static inspection and
leave `tasks.md` unchanged; do not declare the feature approved or converged
at runtime. In either case, report the preparatory result and, when execution
is needed, identify `/implementar-feature <feature-id>` or the equivalent
orchestrator. Do not start it from this skill.
