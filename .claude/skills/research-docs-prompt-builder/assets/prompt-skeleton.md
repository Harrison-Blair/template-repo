<!--
  Conditional prompt skeleton.

  Blocks are delimited by `<!-- BEGIN: NAME -->` / `<!-- END: NAME -->` HTML comments.
  When assembling the final prompt:
    1. Decide which blocks to keep (see SKILL.md table).
    2. Strip the BEGIN/END comment markers from kept blocks.
    3. Walk the lettered section headers (A, B, C, …) and renumber contiguously.
    4. Walk the numbered `Output format` list and renumber to match the kept sections.
    5. Replace every `<PLACEHOLDER>` token with the user's answer.
    6. Prefix every line of the *final* assembled body with `> ` for the file output.

  Do not output BEGIN/END markers or this comment in the final file.
-->

## Research-mode prompt: <TOPIC>

<!-- BEGIN: PROJECT_CONTEXT -->
**Project context**

<PROJECT_CONTEXT_BLOCK>
<!-- END: PROJECT_CONTEXT -->

**What this report is for**

<AUDIENCE_AND_USE_PARAGRAPH — derived from Q1 + Q2: one short paragraph naming the focal topic, the audience, and the doc/location the report fills in. End with one sentence describing the perspective the report should be written from.>

<!-- BEGIN: VERSION_DISCIPLINE -->
**Critical constraint — version discipline**

Current pin(s): <VERSION_PINS>. Discard any guidance that doesn't explicitly cite this version (or behavior demonstrably unchanged with a source).<!-- BEGIN: VOLATILE_AREAS_INLINE --> Treat training-data answers about <VOLATILE_AREAS> as **suspect** until re-verified against current official docs or release notes.<!-- END: VOLATILE_AREAS_INLINE --> Where something changed recently, prefix the claim with `**version-note:**` and cite the change.
<!-- END: VERSION_DISCIPLINE -->

**Source quality**

- **Tier 1 (preferred):** <TIER_1_SOURCES>.
<!-- BEGIN: TIER_2_SOURCES -->
- **Tier 2:** <TIER_2_SOURCES_LIST>.
<!-- END: TIER_2_SOURCES -->
- **Tier 3 (use sparingly, must be dated <CURRENT_YEAR_MINUS_ONE>+):** high-signal community posts, conference talks, named maintainers.
- **Reject:** undated posts; tutorials targeting older versions without an explicit "still applies" note; AI-generated SEO content; forum answers older than <CURRENT_YEAR_MINUS_ONE>.

**What to capture**

**A. <TOPIC>**

<FOCAL_TOPICS — 6–10 numbered sub-topics the report must cover, derived with the user during the interview or surfaced inline during assembly. Each item is one line, imperative, naming a concrete question the report should answer.>

<!-- BEGIN: INTEGRATION_BOUNDARIES -->
**B. Integration boundaries** (each its own section, written from <TOPIC>'s POV)

<NEIGHBORS_LIST — one bullet per neighbor: `- ↔ <Neighbor>: <one-phrase description of the interface, framed from the focal subject's POV>`>
<!-- END: INTEGRATION_BOUNDARIES -->

**C. Anti-patterns specific to <TOPIC>**

Concrete patterns to avoid, each with a one-line rationale and a source.<!-- BEGIN: ANTI_PATTERN_CATEGORIES --> Cover at minimum: <ANTI_PATTERN_CATEGORIES_LIST>.<!-- END: ANTI_PATTERN_CATEGORIES -->

**D. Decisions the maintainer needs to make**

Where the docs are silent or offer multiple equally-supported options, surface the decision as a question with the trade-off rather than picking one. Do not invent a project-specific rule the maintainer hasn't agreed to.

**Output format**

Return one markdown report with these top-level sections, in this exact order:

1. `## Focal: <TOPIC>` — subsections matching A above, in the same order.
2. `## Integration: <neighbor>` — one section per neighbor in B, in the same order as listed. <!-- only if INTEGRATION_BOUNDARIES kept -->
3. `## Anti-patterns`
4. `## Open decisions`
5. `## Sources` — bulleted, each with title, URL, and date.

For every claim that prescribes behavior, attach a parenthetical source (e.g. `(<source name> — <topic>, 2025-10)`). If a claim rests on a single source or is uncertain, mark it `[unverified]`. Where something changed recently in <TOPIC> and the change matters, prefix the claim with `**version-note:**`.

Cap the report at ~<WORD_CAP> words. **Depth over breadth — elide anything obvious from a quick read of the official docs.** The report exists to capture *opinions*, *integration patterns*, and *version-sensitive gotchas*, not to restate reference material.
