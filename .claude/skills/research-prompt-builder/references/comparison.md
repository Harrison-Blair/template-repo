# Comparison / Analytical Research Template

Use when the user is weighing two or more named options, asking "which should I use", or doing decision-support research.

Fill placeholders in `[BRACKETS]`. Mark unconfirmed defaults with `[DEFAULT — confirm]`. Leave anything the user definitely cares about but hasn't specified as `[FILL IN]` — especially the **decision context**, which shapes every other axis.

---

## Template (this is the prompt the user pastes into deep research)

```markdown
I want a comparative analysis of **[OPTION A]** vs **[OPTION B]**[ vs **[OPTION C]** ...] for **[USE CASE]**.

**Decision context**: [DECISION — what is this comparison meant to inform? e.g., "we're picking a managed Postgres provider for a multi-tenant B2B SaaS launching in Q3, expected ~10k tenants in year 1"]
**Audience**: [AUDIENCE — e.g., the engineering team and a non-technical CTO]
**Depth**: [DEPTH — e.g., thorough; should support a real decision, not just an overview]
**Time scope**: [TIME — e.g., current state of each option as of [YEAR]; flag major changes in the last 12 months]
**Geographic / regulatory scope**: [SCOPE — e.g., must support EU data residency; or "not applicable"]
**Exclusions**: [EXCLUSIONS — e.g., no vendor-sponsored comparisons, no marketing-team blog posts, no Medium hot-takes]

### Comparison axes

Compare on the dimensions that actually matter for [USE CASE]. Default starting set — adjust as appropriate for the decision context above:

- **Core capability fit** — does each option do the thing the use case requires, and how well?
- **Performance characteristics** — relevant benchmarks, scaling behavior, latency/throughput envelope
- **Operational cost** — pricing model, total cost of ownership, hidden costs (egress, support tiers, scaling cliffs)
- **Maturity and risk** — production track record, vendor lock-in, exit / migration story
- **Ecosystem and integration** — surrounding tooling, community, third-party support, talent pool
- **Trajectory** — where each option is heading, recent inflection points, deprecations

### What I want at the end

1. **Side-by-side comparison table** on the axes above. Be specific with numbers, not vague qualitatives.
2. **Per-option deep dive.** For each option: strengths, weaknesses, the kind of team and use case it fits best.
3. **Recommendation logic.** Not a single answer. A decision tree: "if [PROPERTY of your situation], pick A; if [PROPERTY], pick B." Be honest about the tradeoffs and where the answer is genuinely close.
4. **What could change the answer.** Emerging factors that might flip the recommendation in 1–2 years (pending features, market shifts, regulatory changes).

### Output format

Markdown document with the four items above as `##` section headings. Pipe tables for the side-by-side. Concrete figures over qualitative comparisons wherever possible — "A is faster" is less useful than "A is ~3× faster on workload X per [benchmark]".

Cite specific claims inline.

End with `## References`. Real, verifiable links only, with a one-sentence note for each. **For every option, cite at least one independent source** — not the vendor's own marketing or docs. Independent sources include: third-party benchmarks (TPC, independent testing labs, academic papers), production postmortems, conference talks from operators, peer-reviewed comparisons. Vendor documentation is fine for capability claims but should not be the only source on performance, cost, or reliability claims. **Omit any source you are uncertain about — do not fabricate URLs, paper titles, or author names.**
```
