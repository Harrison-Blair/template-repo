---
name: research-docs-prompt-builder
description: Generate a tight, constraint-loaded prompt for a Claude.ai Research-mode (also called Deep Research) run, optimized for documentation-shaped output. Trigger this whenever the user wants to write or assemble a research prompt, build a research brief, set up a deep-research run, seed a structured technical report, or kick off documentation-focused research on a topic — including phrases like "research prompt", "research-mode prompt", "research brief", "deep research request", "prompt for Claude Research", or "I want Claude to research X and write me a doc". Trigger even when the user gestures vaguely at wanting "really good research" on a topic. The skill conducts a short interview to elicit topic, scope, version constraints, integrations, and source tiers, then produces a ready-to-paste markdown prompt. Do NOT use this skill if the user wants the research itself done now — use web search / research tools for that. This skill produces the *prompt*, not the research.
---

# Research Prompt Builder

Generates a Claude.ai Research-mode prompt that maximizes the chance of getting a high-quality, structured, source-cited markdown report back.

The prompts this skill produces share a common discipline:
- Pin the research to a specific topic, audience, and output target.
- Force version-aware, source-tiered citation hygiene.
- Demand a fixed report structure (focal subject → integrations → anti-patterns → open decisions → sources).
- Tell the agent to surface trade-offs as open questions rather than invent project rules.

The output is a `.md` file with a `>`-quoted prompt body the user copy-pastes into Claude.ai Research mode.

## Workflow

1. **Interview** the user using the question battery below. Ask in prose, not buttons. Group questions in batches of 2–3 per turn. Accept "skip" / "n/a" / "—" for any question and adapt the output accordingly.
2. **Propose candidates** where you have reasonable knowledge — for sources, volatile areas, anti-pattern categories — but always let the user confirm or edit. Never silently fill these in.
3. **Assemble** the prompt from `assets/prompt-skeleton.md`, omitting blocks whose corresponding answer was skipped and renumbering sections accordingly.
4. **Save** the result to `/mnt/user-data/outputs/research-prompt-<slug>.md`, where `<slug>` is a kebab-case version of the topic. Surface it with `present_files`.
5. **Stop.** Don't run the research yourself; that's a separate operation in a different surface.

## Interview question battery

Run this in three rounds. Don't dump all 11 in one message — that's a wall of text and the user disengages. After each round, take stock of what was answered and adjust the next round based on it (e.g., if Round 1 reveals the topic is non-technical, skip the version questions in Round 2).

### Round 1 — scope (always ask all three)

1. **Focal topic.** What's the subject? Push for specificity. "AI safety" is too broad; "interpretability tooling for sparse autoencoders, 2025+" is good; "Anthropic API tool use, TypeScript SDK ≥0.30" is good. Required.
2. **Audience and use.** Who reads the report and what do they do with it? E.g. "I'll save the output as `docs/api/TOOL_USE.md` for my team's onboarding", or "personal reference for an upcoming architecture decision". Required — this drives the report's framing.
3. **Project context** *(skippable)*. Is there a project the report serves with stack/constraints worth embedding in the prompt? If yes, ask for a 3–8 line context block. If no, skip and the prompt will omit the project-context section.

### Round 2 — version & sources

4. **Version sensitivity.** Is this topic version-pinned (libraries, products, APIs, regulations)? If yes, list the pin(s) — exact versions, dates, jurisdictions. If timeless ("how to write a good design doc"), skip and the version-discipline block is omitted.
5. **Volatile areas** *(only if Q4 was answered)*. APIs / behaviors / claims known to have churned recently and that the agent must re-verify. Propose 2–4 candidates from your own knowledge if you have them; user confirms or edits. If none come to mind, the prompt says `none flagged — verify the report still cites current docs`.
6. **Tier 1 sources.** Authoritative sources by name — vendor docs, official repos, RFCs, named maintainers, primary research. Propose candidates; user confirms. Required.
7. **Tier 2 sources** *(skippable)*. Adjacent official docs that are likely to come up.

### Round 3 — structure

8. **Integration boundaries** *(skippable)*. Other topics the focal subject touches that the report should cover *from the focal POV*. Each one phrase: "↔ React: how the Compiler interacts with Server Components". If the topic is self-contained (e.g. "writing a good PRD"), skip — the integrations section disappears from the output.
9. **Anti-pattern categories** *(skippable)*. Specific failure modes the report should explicitly cover (security, performance, data integrity, version skew, etc.). If skipped, the prompt asks the agent to surface them itself.
10. **Word cap.** Default ~3000. Ask only if the user seems to want something different; otherwise just use the default.
11. **Output target path** *(if Q2 didn't already cover it).* The doc filename / location the report fills in. Used in the prompt's framing line.

## Assembling the prompt

Read `assets/prompt-skeleton.md`. It has labelled blocks delimited by `<!-- BEGIN: BLOCK_NAME -->` / `<!-- END: BLOCK_NAME -->`. Each block is independent — keep or drop based on the answers, then strip the comment markers from what remains.

Block-to-answer mapping:

| Block | Keep when |
|---|---|
| `PROJECT_CONTEXT` | Q3 answered |
| `VERSION_DISCIPLINE` | Q4 answered |
| `VOLATILE_AREAS_INLINE` | Q5 answered with content (else use `none flagged` fallback inside `VERSION_DISCIPLINE`) |
| `TIER_2_SOURCES` | Q7 answered |
| `INTEGRATION_BOUNDARIES` | Q8 answered |
| `ANTI_PATTERN_CATEGORIES` | Q9 answered |
| Everything else | Always |

After dropping blocks, walk the section headers (A, B, C…) and renumber so they're contiguous. Same for the `Output format` numbered list — if integrations dropped, the integration entry disappears and following entries renumber.

When you fill placeholders in the skeleton, write naturally — don't leave robotic phrasing like "<TOPIC> itself" if the topic noun reads awkwardly that way. Adjust to fit grammar.

## Output file shape

The file you save mirrors the example shape — a short usage header, a `---` separator, then the `>`-quoted prompt body the user pastes verbatim into Research mode. Skeleton:

```markdown
# Research-mode prompt — <Topic>

<One-paragraph explainer derived from Q1 + Q2: what this prompt is for and where the report lands. Mention any attached-files instruction if the user said the prompt should reference attachments.>

## How to use

1. Open Claude.ai → **Research** mode.
2. [If user mentioned attached files] Attach: <files>.
3. Copy everything below the `---` rule labelled "**The prompt**" and paste as the message body.

---

## The prompt

> <assembled prompt body, every line prefixed with `> `>
```

## Style notes for the generated prompt

- Be terse. Where a block can be omitted, omit — don't pad with weak content. A short, sharp prompt produces better research than a long flabby one.
- Use ranges and concrete numbers ("~6–10 items", "<3000 words"), not vague qualifiers.
- The prompt must explicitly demand inline citations, an `[unverified]` marker for single-source or speculative claims, and a `**version-note:**` prefix for behavior that recently changed.
- Quote the entire prompt body with `>` so the paste-boundary is visually unambiguous.
- Don't editorialize about how good the prompt is. Hand the file over and stop.

## Anti-patterns when running this skill

- **Dumping all 11 questions at once.** The user stops reading at question 4. Always batch.
- **Silently filling in sources from training data.** That's the exact failure mode the prompt is designed to prevent. Propose, don't assume.
- **Forcing the integration-boundaries section** on a self-contained topic. If the user skipped Q8, the section must disappear cleanly.
- **Leaving template placeholders in the output.** Every `<…>` token gets replaced or the line gets removed.
- **Running the research yourself.** This skill ends at the file. Don't be helpful past the boundary.
