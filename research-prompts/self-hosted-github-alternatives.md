I want a comparative analysis of **self-hostable GitHub alternatives** for **backing up and hosting personal Git repositories with CI/CD support via self-hosted Docker runners**.

Specifically, compare at minimum:

- **Gitea**
- **Forgejo** (the Codeberg-led soft fork of Gitea)
- **GitLab Community Edition** (self-managed)
- **Gogs**
- **OneDev**

If there are other credible self-hostable options that materially fit the use case below (e.g., Sourcehut self-hosted, Bonsai, or anything notable I've missed), include them — but only if they meet the hard requirements.

**Decision context**: Solo developer evaluating a self-hosted Git server. Some projects will live on the new forge as their **primary remote** (full replacement for GitHub); others will start as **one-way pull mirrors** from GitHub for disaster-recovery backup, and may later be promoted to primary. So the forge must do *both* well: be a credible day-to-day primary remote, and reliably mirror external GitHub repos on a schedule. Wants to keep using `git` as the underlying VCS (so anything that requires migrating off git, e.g. Fossil/Pijul, is out of scope). Wants built-in CI/CD support, with the ability to register self-hosted Docker-container-based runners on hardware the user already owns. The user is comfortable relearning a different pipeline syntax (e.g., GitLab CI YAML) — GitHub Actions compatibility is a *nice-to-have*, not a hard requirement, so don't penalize options that have a strong but non-Actions CI. Hosting will be on the user's own infrastructure — no managed/SaaS tier needed. Optimize for: low operational overhead, healthy long-term project trajectory (so the choice doesn't bit-rot in 2–3 years), and a robust mirroring story.

**Audience**: A senior software engineer who lives in `git` daily and is comfortable running Docker, reverse proxies, and Linux services, but doesn't want to babysit the forge itself.

**Depth**: Thorough — should be enough to make a real decision, not just an overview. Roughly a 20–30 minute read.

**Time scope**: Current state as of 2026. Explicitly flag any major inflection points in the last ~24 months, especially around Gitea/Forgejo governance, GitLab licensing/feature changes, and the maturity of each project's Actions/CI implementation.

**Geographic / regulatory scope**: Not applicable — single-developer self-hosting, no compliance constraints.

**Exclusions**:
- No vendor/marketing blog posts as the primary source for any capability or performance claim.
- No Medium hot-takes, no LLM-generated "top 10" listicles, no SEO comparison farms.
- Skip anything that requires moving off `git` as the VCS (e.g., Fossil, Pijul, Mercurial-only forges).
- Skip cloud-only / SaaS-only options (Bitbucket Cloud, GitHub itself, GitLab.com hosted, etc.) — must be self-hostable on commodity hardware.

### Comparison axes

Compare on the dimensions that actually matter for the use case above. Use this set, and feel free to add a dimension if something important doesn't fit:

- **Core capability fit** — git hosting, web UI quality, PR/MR workflow, issues, releases, packages/registry.
- **Mirroring & backup** — first-class support for *pull* mirrors (auto-syncing an external GitHub repo into the forge on a schedule) and *push* mirrors (replicating to an external remote). How is mirror auth handled (PATs, SSH keys), can it mirror private repos, what happens to issues/PRs/releases on a mirror, and how easy is it to promote a mirror to a primary repo later?
- **CI/CD support** — does it have a built-in CI system? Pipeline syntax (own DSL vs GitHub Actions-compatible vs other) — note compat as a feature but don't weight it heavily; the user is willing to learn a new syntax. What's the self-hosted Docker runner story (`act_runner`, `gitlab-runner`, custom)? Concurrency, caching, artifacts, secrets handling, and how the runner is registered/managed.
- **Self-hosting operational cost** — RAM/CPU/disk footprint at idle and under light load, official Docker/Compose/Helm support, upgrade story, backup/restore story, observability.
- **Maturity and risk** — production track record, single-maintainer vs multi-maintainer governance, financial/organizational backing, license, fork/exit story (especially relevant given the Gitea→Forgejo split — explain what actually happened, what diverges today, and where each is heading).
- **Ecosystem and integration** — third-party clients, IDE integrations, GitHub-compat API surface, migration tooling from GitHub, community size.
- **Trajectory** — release cadence, recent inflection points, roadmap signals, any concerning trends (slowing commits, governance disputes, license shifts).

### What I want at the end

1. **Side-by-side comparison table** on the axes above. Be specific with numbers wherever possible — RAM at idle, lines-of-config to stand up, time to first green build on a self-hosted runner, etc. Vague qualitatives ("lightweight", "fast") are not useful without a number.
2. **Per-option deep dive.** For each option: strengths, weaknesses, the kind of user and workload it fits best, and any gotchas a solo self-hoster would hit in the first month.
3. **Recommendation logic.** Not a single answer. A decision tree: "if you care most about [PROPERTY], pick X; if [PROPERTY], pick Y." Be honest about where the answer is genuinely close (I expect Gitea vs Forgejo to be one of those).
4. **What could change the answer.** Emerging factors that might flip the recommendation in 1–2 years — e.g., GitLab CE feature removals, Forgejo Actions reaching parity with GitHub Actions, a new entrant gaining traction, or shifts in the mirror/replication tooling story.

### Output format

Markdown document with the four items above as `##` section headings. Pipe tables for the side-by-side. Concrete figures over qualitative comparisons wherever possible.

Cite specific claims inline.

End with `## References`. Real, verifiable links only, with a one-sentence note for each. **For every option, cite at least one independent source** — not the project's own marketing, docs, or official blog. Independent sources include: third-party benchmarks, self-hoster postmortems, conference talks, peer-reviewed comparisons, well-regarded blog deep-dives by named operators (not anonymous SEO sites). Project documentation is fine for capability claims but must not be the only source on performance, reliability, or governance claims. **Omit any source you are uncertain about — do not fabricate URLs, repo names, author names, or release version numbers.**
