# Technical Research Template

Use when the topic is a specific technology, framework, library, protocol, architecture, or implementation question.

Fill placeholders in `[BRACKETS]`. Mark unconfirmed defaults with `[DEFAULT — confirm]`. Leave anything the user definitely cares about but hasn't specified as `[FILL IN]`.

---

## Template (this is the prompt the user pastes into deep research)

```markdown
I want a deep technical research report on **[TOPIC]**.

**Audience**: [AUDIENCE — e.g., a senior engineer evaluating this for a production system]
**Depth**: [DEPTH — e.g., exhaustive deep-dive; I want to come out understanding the failure modes and operational characteristics, not just the marketing]
**Time scope**: [TIME — e.g., focus on the current state of the art; cite foundational work where relevant; sources from [YEAR]+ where possible]
**Ecosystem / platform scope**: [SCOPE — e.g., the JVM ecosystem; or "Linux only"; or "not applicable"]
**Exclusions**: [EXCLUSIONS — e.g., skip vendor marketing pages, no SEO-driven blog spam, no AI-generated content farms]

### What I want answered

1. **What is [TOPIC] and what problem does it solve?** A precise technical definition, not a marketing one. Distinguish it from adjacent technologies it gets confused with.
2. **How does it work mechanically?** Cover the core algorithms, data structures, protocols, and operational model. Diagrams (mermaid welcome) where they help.
3. **Operational characteristics.** Performance envelope, failure modes, concurrency model, resource consumption, scaling behavior under realistic load.
4. **Alternatives and how it differs.** Compare to the closest 2–3 alternatives on the dimensions that actually matter for the use case implied above.
5. **Gotchas.** Things that bite teams in production. Footguns, surprising defaults, common misconfigurations, debugging pain points.
6. **Maturity and ecosystem.** Maintainer health, release cadence, community size, surrounding tooling, who runs this in production at scale.
7. **Trajectory.** Significant recent changes, items on the roadmap, anything being deprecated.

### Output format

Produce a single markdown document with the seven items above as `##` section headings. Use `###` subheadings for sub-topics, fenced code blocks for code samples and config, pipe tables for comparisons.

Cite specific claims inline (e.g., "[1]" with a corresponding entry in References, or `[source name](url)`).

End with a `## References` section. Every reference must be a real, verifiable link with a brief one-sentence note explaining what it is and why it's cited. Prefer **primary sources** (official docs, RFCs, source code, peer-reviewed papers, maintainer talks, language specifications) over secondary commentary. If you are uncertain a source is real or directly supports the claim, **omit it** rather than include a guess. Do not fabricate URLs, paper titles, or author names.
```
