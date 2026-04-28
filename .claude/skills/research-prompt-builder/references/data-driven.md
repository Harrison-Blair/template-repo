# Data-Driven Research Template

Use when the topic is quantitative — statistics, market sizing, surveys, demographics, financial figures, trends over time.

Fill placeholders in `[BRACKETS]`. Mark unconfirmed defaults with `[DEFAULT — confirm]`. Leave anything the user definitely cares about but hasn't specified as `[FILL IN]` — particularly time and geographic scope, which are load-bearing for this domain.

---

## Template (this is the prompt the user pastes into deep research)

```markdown
I want quantitative research on **[TOPIC]**.

**Audience**: [AUDIENCE — e.g., an analyst preparing a strategy memo for an exec audience]
**Depth**: [DEPTH — e.g., a thorough numbers-driven brief, ~10-page equivalent with charts and tables]
**Time scope**: [TIME — important; specify the year range explicitly, e.g., "2018–2025 with a focus on the last three years"]
**Geographic scope**: [SCOPE — important; specify country/region and whether to break down by sub-region, e.g., "global, with separate breakouts for US, EU, and APAC"]
**Exclusions**: [EXCLUSIONS — e.g., no industry reports paywalled behind sign-up walls; no LLM-generated stat collections; no figures without a named primary source]

### What I want

1. **Headline numbers.** The 5–10 most important data points on this topic. Each one with a primary source and the date the figure refers to (which may differ from the publication date).
2. **Time series.** How have the numbers moved across [TIME WINDOW]? Identify inflection points and what drove them. Pipe tables and/or mermaid charts.
3. **Breakdowns.** Cut by [DIMENSIONS — e.g., region, vertical, company size, demographic segment]. Lead with the cuts that reveal something non-obvious.
4. **Source quality assessment.** For each major figure, name the primary source (the org that produced the data) and how it was measured (sampling method, scope, definitional choices). Where multiple credible sources disagree, show the range and explain the disagreement rather than picking one.
5. **What the data does and doesn't tell us.** Limits: definitional issues, sampling biases, geographic or temporal gaps, known data-quality problems. Don't overclaim.

### Output format

Markdown document with the five items above as `##` section headings. Pipe tables for the headline numbers and time series. Mermaid charts welcome for trends.

For every quantitative claim, cite the primary source inline — e.g., "Global EV sales reached 14.2M units in 2023 ([IEA Global EV Outlook 2024](url))." Inline links or footnote-style references both fine, as long as every figure is traceable.

End with `## References`. Each entry must include: source name, what it is (e.g., "annual industry tracker from the International Energy Agency"), the URL, and the year of the data being cited. Prefer **primary publishers** (IEA, Eurostat, BLS, Census Bureau, OECD, World Bank, national statistics offices, peer-reviewed papers, registered SEC filings) over aggregator blogs and SEO content. If a number cannot be sourced confidently from a primary publisher, **omit it** — do not invent figures, percentages, or dollar amounts to fill out the report.
```
