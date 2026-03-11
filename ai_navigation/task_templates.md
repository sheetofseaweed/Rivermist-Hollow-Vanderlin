# Task Templates

These are copy-paste templates for giving agents better task briefs in this repository.

Use them when you want the agent to start cleanly, avoid broad scans, and route itself through the `ai_navigation/` navigation layer.

Default routing rule for all templates:

```text
Default mode: Fast Start.
Start with ai_navigation/router.md.
Use exactly one small helper first.
Escalate to larger navigation docs only if still ambiguous.
```

If startup choice itself is unclear, open `ai_navigation/start_matrix.md`.

## 1. Minimal Fast Task

Use when you already know the system and want the shortest workable brief.

```text
Goal:
<what should be fixed / changed / explained>

Context:
<type path / SS* / directory / feature name>

Constraints:
<what not to touch>

Verification:
<what must be true in the end>

Repository guidance:
Default to Fast Start: ai_navigation/router.md. Use one small helper first; for minimal tasks this is usually ai_navigation/entrypoints.md or ai_navigation/type_index.md.
```

## 2. Bugfix Template

Use for a gameplay or runtime bug when you want analysis plus a concrete fix.

```text
Goal:
Fix a bug in <feature/system>.

Where to start:
<type path / subsystem / likely directory>

Symptoms:
- <what the player/admin sees>
- <when it happens>

Reproduction:
1. <step>
2. <step>
3. <bad result>

Expected behavior:
- <correct result>

Constraints:
- Keep the fix minimal.
- Do not refactor unrelated systems.
- Check whether modular_rmh extends the same path.

Human check:
- If the fix touches a shared branch, hot path, or subsystem, stop for approval before edits.

Verification:
- Confirm the reproduced scenario now behaves correctly.
- Mention which files and runtime owners were involved.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. For bug reports, prefer ai_navigation/debug_routes.md first; add ai_navigation/runtime_flow.md or ai_navigation/subsystem_map.md only if runtime ownership is involved.
```

## 3. New Feature Template

Use when adding a mechanic, new content, or an extension to an existing system.

```text
Goal:
Add <new feature>.

Target system:
<jobs / spells / status effects / AI / mapping / economy / etc.>

Expected shape:
- New type path(s): <if known>
- User-facing behavior: <what the player/admin sees>
- Runtime owner: <if known; e.g. SSmagic, SSmigrants, SSmapping>
- Usage surface:
  - who uses it now: <exact audience>
  - who may use it later: <real future users, if any>
  - frequency: <action / state change / while active / per step / per tick>
  - concurrency: <how many instances can exist in one round>
- Feature breakdown:
  - delivery channel: <crafting / loadout / loot / merchant / admin / etc.>
  - base archetype: <closest existing thing to extend>
  - delta set: <what changes from the base>
  - effect carrier: <override / proc / action / status / component / element / subsystem>

Constraints:
- Reuse existing patterns in this repo.
- Prefer extending the existing type tree over inventing a parallel system.
- Check whether the change belongs in core code or in modular_rmh.

Human check:
- If this affects a broad audience, shared branch, or hot path, get approval before edits.
- If future users are uncertain, ask instead of assuming.

Verification:
- Describe how to trigger the feature.
- Describe what success looks like.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. For new mechanics, begin with ai_navigation/content_creation.md. If the request is still vague, open ai_navigation/content_breakdown.md. If the implementation form is still fuzzy after that, open ai_navigation/content_patterns.md. Then use ai_navigation/entrypoints.md or ai_navigation/type_index.md. Add ai_navigation/system_dependencies.md, ai_navigation/system_map.md, and ai_navigation/type_tree.md only if the feature touches multiple branches.
```

## 4. Refactor / Cleanup Template

Use when the behavior should remain the same but the code needs cleanup.

```text
Goal:
Refactor <module/system> without changing behavior.

Current location:
<directory / type path / subsystem>

Why:
- <duplication / readability / dead code / coupling / maintenance>

Constraints:
- No gameplay changes.
- No balance changes.
- Keep public behavior stable.
- Call out any risky behavior-preserving assumptions.

Verification:
- Explain how you confirmed behavior is unchanged.
- Mention any residual risk.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. Use one small helper first, then add ai_navigation/system_dependencies.md, ai_navigation/architecture.md, and ai_navigation/system_map.md only as needed.
```

## 5. Architecture / Investigation Template

Use when you want explanation, root-cause analysis, or a plan before editing.

```text
Goal:
Analyze how <system> works.

Focus:
- <runtime flow / ownership / inheritance / dependency map / extension points>

Known anchors:
- <type path / SS* / directory / user scenario>

Output needed:
- <explanation / root cause / implementation plan / file map>

Constraints:
- No code changes unless explicitly approved.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. Pick the one helper that best matches the investigation anchor, then escalate to larger navigation docs only if that route is insufficient. Switch to ai_navigation/AGENTS.md only if you want Guided Start.
```

## 6. Code Review Template

Use when you want findings instead of implementation.

```text
Goal:
Review <change / branch / files> for bugs, risks, regressions, and missing tests.

Scope:
<paths / feature area / subsystem>

Review focus:
- correctness
- runtime ownership
- inheritance / type tree fit
- subsystem interactions
- modular_rmh overlap

Constraints:
- Findings first.
- Keep summary brief.
- Do not rewrite code unless asked.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. Usually begin with ai_navigation/entrypoints.md; add ai_navigation/system_dependencies.md and ai_navigation/subsystem_map.md when ownership or handoff matters.
```

## 7. Runtime / Performance Template

Use for lag, MC pressure, processing, or scheduler issues.

```text
Goal:
Investigate runtime/performance issue in <system>.

Known anchors:
- subsystem: <SS* if known>
- feature: <what was happening>
- symptom: <lag / hitching / runtime / runaway processing>

What to determine:
- who owns runtime execution
- where the hot path lives
- whether the issue is in scheduling, signals, or high-frequency processing

Constraints:
- Prioritize identifying the owner and the narrowest hot path.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. For runtime/performance work, begin with ai_navigation/runtime_flow.md or ai_navigation/debug_routes.md, then ai_navigation/subsystem_map.md, then ai_navigation/architecture.md if needed.
```

## 8. Content / Data Template

Use for jobs, outfits, spells, map templates, or gameplay data additions.

```text
Goal:
Add or modify content for <jobs / outfits / spells / map template / migrant wave / antagonist / status effect>.

Likely location:
<type path / directory>

Desired result:
- <new content>
- <availability / unlock condition / trigger>
- Usage surface:
  - <who uses it>
  - <how often it triggers>
  - <how many instances may exist at once>
- Feature breakdown:
  - <how it enters the game>
  - <what existing thing it extends>
  - <what actually changes>
  - <where the new behavior should live>

Constraints:
- Follow existing content conventions.
- Keep balance and role gating in mind.
- Check both core and modular_rmh before adding a duplicate branch.

Human check:
- If this should work for a high-count branch, broad audience, common object family, or large NPC/AI population, confirm the intended scope before edits.

Verification:
- Explain how the new content is reached or spawned.

Repository guidance:
Default to Fast Start: ai_navigation/router.md. For content additions, begin with ai_navigation/content_creation.md. If the request is still fuzzy, use ai_navigation/content_breakdown.md. If pattern selection is unclear after that, use ai_navigation/content_patterns.md, then ai_navigation/type_index.md or ai_navigation/entrypoints.md. Use ai_navigation/type_tree.md only if inheritance depth matters, and add ai_navigation/system_dependencies.md if the content branches into other systems.
```

## 9. Map Refresh / Migration Template

Use when updating the `ai_navigation/` layer itself or porting it to another codebase.

```text
Goal:
Refresh the repository navigation layer / migrate the AI mapping system to <target repo>.

Scope:
- refresh only / partial rebuild / full rebuild / migration
- docs only unless explicitly approved otherwise

Known drift:
- <what changed in the repo, if known>
- <which navigation docs are most likely stale>

Constraints:
- Rebuild from source, not from the old navigation docs alone.
- Keep the routing layer cheap.
- Preserve the reasoning model even if exact paths change.

Output needed:
- updated navigation docs
- short note on what changed
- any missing equivalents in the target repo

Verification:
- router targets exist
- major entrypoints still resolve
- runtime owners were rechecked
- no source code changed unless explicitly requested

Repository guidance:
Use Maintenance Start. Start with ai_navigation/update_policy.md. Rebuild runtime ownership and routing layers before deep reference layers.
```

## Recommended Human Workflow

If you want a future agent to work well from the first turn, do this:

1. Send the goal using one of the templates above.
2. Then send the repository and tell the agent which startup mode to use.

That matches the intended operating model for this repository:

1. Here is the goal.
2. Here is the repository with guidance.

Default recommendation:

```text
Start with ai_navigation/router.md.
```
