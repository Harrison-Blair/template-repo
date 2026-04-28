---
name: research-prompt-builder
description: Build a high-quality research prompt for Claude.ai's deep research mode. Use whenever the user wants to "build a research prompt", "write a deep research prompt", "set up a deep research task", "draft a research brief", or describes any topic they want to research deeply. The skill auto-picks a domain template (Technical / Theory / Data-Driven / Comparison-Analytical), drafts a complete prompt, saves it to `./research-prompts/<slug>.md`, and asks targeted refinement questions. Trigger this even when the user just says "I want to research X" or "help me research Y" — the skill exists to shape rough ideas into usable deep research prompts.
---

# Research Prompt Builder

Build a prompt for Claude.ai's deep research mode. Deep research takes a long, well-scoped prompt and returns a markdown report with citations — but the report is only as good as the prompt. This skill helps the user draft, save, and iterate on that prompt.

## Mental model

The user has a research idea — sometimes a sentence, sometimes a paragraph. Your job is to turn it into a deep research prompt the user can paste into Claude.ai. The output of *the skill* is a `.md` file containing the prompt. The output of *deep research* (when the user later runs that prompt) is a separate markdown report — that's why every template ends with explicit instructions to deep research about output format and references.

Don't run the research yourself. Don't fetch sources. Your only job is to produce a high-quality prompt and save it to a file.

## Flow

1. Pick a domain (Technical / Theory / Data-Driven / Comparison-Analytical).
2. Read the matching template from `references/`.
3. Fill the template with what the user gave you, plus reasonable defaults for anything missing.
4. Save the draft to `./research-prompts/<slug>.md` (create the dir if missing).
5. Show the draft in chat and ask 2–3 targeted refinement questions.
6. Iterate on the file based on user feedback.

Draft *before* interviewing. The user gets more out of reacting to a concrete draft than answering questions in the abstract. Defaults the user doesn't fix are cheap; questions before a draft are friction.

## Step 1: Pick a domain

Read the user's request and route to one of four templates. Each template lives in `references/`. Use these heuristics:

| Domain | Template file | When to pick |
|---|---|---|
| **Technical** | `references/technical.md` | The topic is a specific technology, framework, library, protocol, architecture, or implementation question. Cues: framework/language names, "how does X work", "best practices for", "implementing", "architecture of". |
| **Comparison-Analytical** | `references/comparison.md` | The user is weighing two or more named options, asking "which should I use", "X vs Y", "pros and cons of A and B", or doing decision-support research. |
| **Data-Driven** | `references/data-driven.md` | The topic is quantitative — statistics, market sizing, surveys, demographics, financial figures, trends over time. Cues: "stats", "data on", "market size", "trends", "by year/region", "how many". |
| **Theory/General** | `references/theory.md` | Anything that isn't one of the above. Conceptual, historical, social, cultural, scientific consensus, biographical. Default fallback. |

If two domains both fit (e.g., "compare Postgres vs MySQL performance under heavy writes" — Technical AND Comparison), pick **Comparison** — it's the more specific framing, and the Comparison template can absorb technical detail. If the request is genuinely ambiguous, briefly state your read in one sentence ("Reading this as Theory because the focus is on the philosophical question, not a specific framework — sound right?") and confirm before drafting. Don't over-confirm: skip the question on clear cases.

## Step 2: Read the template, then draft

Read the chosen template file. Each template is a scaffolded deep research prompt with placeholders in `[BRACKETS]` and domain-specific section guidance.

Filling rules:

- **Use what the user gave you directly** wherever it fits.
- **Pick sensible defaults** for things the user didn't specify — but mark them `[DEFAULT — confirm]` so the user can spot and override them.
- **Leave `[FILL IN]`** for anything the user definitely cares about but didn't supply, where guessing would be wrong (e.g., never invent a regulatory jurisdiction or a specific dataset year).
- **Don't strip the template's deep-research instructions** about output format and references. Those are the load-bearing part — they're what make the eventual report well-structured and properly cited.

Every template enforces the four universals so they end up in every prompt:

1. **Audience + depth** — who the report is for, how exhaustive
2. **Time / geographic scope** — recency cutoff, jurisdictional scope
3. **Explicit exclusions** — what NOT to cover, source types to avoid
4. **Output structure + References** — markdown with section headings, ending with a `## References` section of real verifiable links

## Step 3: Save to a file

Save to `./research-prompts/<slug>.md` relative to the current working directory.

- `<slug>` is the topic in kebab-case, max ~60 chars. Strip punctuation, lowercase, collapse whitespace to hyphens. Example: "Postgres vs MySQL for read-heavy workloads" → `postgres-vs-mysql-read-heavy.md`.
- If `./research-prompts/` doesn't exist, create it.
- If the slug collides with an existing file, append `-2`, `-3`, etc. — never overwrite without asking. The user may have an earlier draft they want to keep.

## Step 4: Show the draft and ask 2–3 refinement questions

Print the full draft prompt back to the user in a fenced markdown code block (so they can see exactly what's in the file). Then ask 2–3 questions tailored to what's *most generic or missing* in the draft. Don't ask all of them every time — pick the ones that matter most for this specific topic.

Question bank to pull from:

- *Audience*: "I'm framing this for [X] — does that match? Should the report assume more or less domain knowledge?"
- *Depth*: "Quick brief (5–10 min read), thorough overview, or exhaustive deep-dive?"
- *Time scope*: "Any recency cutoff? E.g. 'sources from 2023+' or 'historical context welcome'."
- *Geographic / regulatory scope*: "Is this US-only, EU-focused, global, or [other]?"
- *Sources to prioritize*: "Specific publications, authors, repos, or datasets you want deep research to lean on?"
- *Sources to exclude*: "Anything to skip? E.g. 'no Reddit/Quora', 'avoid vendor blogs', 'no LLM-generated stat collections'."
- *(Comparison only) Decision context*: "What's the decision this is meant to inform?"
- *(Comparison only) Axes*: "Are the comparison axes the right ones, or are there dimensions you care about that I missed?"
- *(Data-Driven only) Quantitative bar*: "Do you want primary data (raw figures, charts), or is summarizing reported figures enough?"
- *(Technical only) Production angle*: "Should this lean toward operational/production concerns, or toward the conceptual/architectural side?"

Phrase questions so they're easy to skip. The draft is already complete and usable; the questions are for refinement, not gatekeeping.

## Step 5: Iterate

When the user gives feedback (answers to your questions, free-form changes, or both):

- Use `Edit` for surgical changes (a section, a sentence, a placeholder).
- Use `Write` only for substantial rewrites.
- Re-show only the changed section in chat — don't re-paste the whole file unless it materially changed.

When the user says they're happy, point them at the file path and remind them they can paste the contents into Claude.ai's deep research mode.

## Notes on the templates

The templates in `references/` are themselves prompts addressed *to deep research* — second-person instructions to a research assistant. When you fill them in, you're producing the user's deep research prompt; you are not running research yourself. Keep the "you" in the templates as "you, deep research", not "you, the model running this skill".

Each template has its own structure tuned to its domain. Don't substitute one for another — a Technical scaffold applied to a historiography question will produce a worse prompt than the Theory scaffold, even if both technically work.

If the user explicitly asks for a structure that doesn't match any template (e.g., "I want a literature review specifically"), use the closest template as a starting point and adapt — the templates are scaffolds, not laws.
