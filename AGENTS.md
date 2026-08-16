# Frame Gambit development instructions

## Delegation policy

- Use subagents for concrete, bounded reviews or independent investigations when the user asks for delegation.
- Prefer `gpt-5.6-luna` for inexpensive searches, documentation checks, narrow UI reviews, and straightforward consistency audits.
- Prefer `gpt-5.6-terra` for broader code audits, architecture checks, and medium-risk implementation review.
- Reserve `gpt-5.6-sol` for security/combat-safety gates, difficult lifecycle bugs, release-blocking reviews, or a final audit after cheaper agents have narrowed the problem.
- Give every code-changing worker explicit file ownership and remind it not to revert other concurrent edits.
- Explorers are read-only unless their task explicitly grants ownership of named files.
- Avoid asking multiple agents to repeat the same full-repository audit. Split work by subsystem and consolidate their findings in the primary agent.

## Project safety

- Frame Gambit must layer alpha/visibility behavior over Blizzard and other addons without editing their source files or SavedVariables.
- Never reparent, restyle, Show/Hide, or change secure attributes of third-party frames as part of visibility control.
- Preserve host alpha and restore it conditionally when ownership ends.
- Guard Retail secret values before branching, comparison, arithmetic, or formatting.
- Treat combat lockdown, pooled-frame identity changes, and addon/profile rebuilds as release gates.
- Keep shared evaluators and discovery scans bounded; do not add per-frame `OnUpdate` loops.

