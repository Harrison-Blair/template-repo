I want a comparative analysis of **self-hostable applications that can replace Google Calendar** for a single-user personal-productivity setup.

**Decision context**: I am moving off Google Calendar for a self-hosted alternative. I have a dedicated always-on Linux host I can run the service on, and a separate OpenMediaVault NAS (3 TB usable, RAID5, EXT4) that will hold backups but will not run the calendar service itself. I use an iPhone daily and need first-class mobile access; I also want a web UI for desktop use. This is a single-user setup — no shared/family calendars, no need to send invitations to other Google Calendar users from this instance. iOS sync does NOT need to be as fast as Google Calendar; CalDAV polling at the iOS-default ~15-minute cadence is acceptable, and real APNs push is not a requirement. I want as close to Google Calendar feature parity as I can reasonably get for a self-hosted tool. The goal of this report is to let me confidently pick one option to deploy, not just to learn the landscape.

**Bonus consideration — contacts (CardDAV)**: I currently keep contacts in iCloud (iPhone Contacts), not Google Contacts, so contacts sync is not a hard requirement. However, most candidates here are CalDAV+CardDAV combo servers, so if a tool offers contacts sync as a near-free addition I would consider consolidating off iCloud Contacts onto the same self-hosted instance. Treat CardDAV/contacts support as a tie-breaker axis, not a primary one — do not exclude calendar-only options on this basis, but do call out which options would let me retire iCloud Contacts cleanly.

**Audience**: Me — technically literate, comfortable with Docker/`docker compose`, comfortable editing config files, but not a sysadmin by trade. Assume Linux/self-hosting fluency; do not assume groupware/CalDAV expertise. Explain CalDAV/CardDAV-specific concepts when they are load-bearing for the comparison.

**Depth**: Thorough. This should support a real deployment decision, including catching gotchas before I install. Not just an overview.

**Time scope**: Current state of each option as of 2026. Strongly prioritize sources from 2024-onward; flag any major changes (rewrites, license changes, project forks, abandonment) in the last 18 months. Note when a project's last meaningful release was if it is older than 12 months.

**Geographic / regulatory scope**: Not applicable — personal use, no compliance requirements.

**Exclusions**:
- No hosted/SaaS calendar services (Fastmail, Proton Calendar, Zoho, etc.) — must be self-hostable on my own hardware.
- No Android-only ecosystems — iOS support is mandatory.
- No options that require a paid license for personal/single-user self-hosting (note this if it applies; do not include them in the final ranking).
- Skip vendor marketing pages and SEO listicles ("Top 10 Google Calendar Alternatives 2025"). Prefer project documentation, GitHub/Codeberg repos, r/selfhosted threads with substantive discussion, and independent blog posts from people who actually deployed the tool.
- No LLM-generated comparison articles.

### Candidates to evaluate

Cover at minimum the following, and add any other actively-maintained self-hostable calendar option that meets the requirements (iOS + web UI + Google-Calendar-like feature set):

- **Nextcloud** (with the Calendar app)
- **Radicale**
- **Baïkal**
- **SOGo**
- **EteSync / Etebase**
- **AgenDAV** (as a web frontend over a CalDAV server)
- **Mailcow** / **Mail-in-a-Box** (only the calendar component, if separable)
- Any Rust/Go/modern-stack CalDAV server that has emerged recently and is plausibly production-ready for a single user

If a project is effectively unmaintained (no commits in >12 months, unanswered security issues, archived repo), say so explicitly and exclude it from the final recommendation, but mention it briefly so I know it was considered.

### Comparison axes

Compare on the dimensions that actually matter for this use case:

- **Google Calendar feature parity** — events, all-day events, recurring events (including complex RRULEs and exceptions), reminders/notifications, multiple calendars per user, calendar colors, time-zone handling, event invitations/attendees, free-busy queries, availability sharing, search. Be specific about which of these each option supports vs. partially supports vs. doesn't support.
- **iOS support** — does iOS's native Calendar app sync via CalDAV out of the box? Push speed itself is not a deciding factor (polling at iOS default ~15 min is fine), but flag any options that fail to sync reliably *at all* on iOS, or that have known iOS-specific bugs around recurring events, time-zone drift, or invitation handling. Is a third-party iOS client recommended over native?
- **CardDAV / contacts (tie-breaker only)** — does the option also serve CardDAV? How well does iOS Contacts sync against it? Could it credibly replace iCloud Contacts for a single user if I chose to consolidate? Do not weight this heavily — it is a "would be nice if it comes for free" axis.
- **Web UI quality** — does the project ship its own web UI, depend on another (e.g., AgenDAV, Nextcloud Calendar), or have none? Day/week/month views, drag-to-create, drag-to-reschedule, keyboard shortcuts, mobile-browser usability.
- **Deployment complexity** — Docker image quality, official `docker-compose.yml`, dependencies (DB, web server, auth backend), reverse-proxy/TLS expectations, single-binary vs. PHP-stack vs. JVM-stack, resource footprint (RAM/CPU at idle and under typical single-user load).
- **Backup story** — what exactly do I need to back up to the NAS to fully restore (DB dump? file tree? both)? Are there documented restore procedures? Any known footguns (e.g., DB and file backups must be taken atomically)?
- **Migration from Google Calendar** — can I import a Google Takeout `.ics` cleanly? Are recurring events / exceptions / attendees preserved? Any reported data-loss issues?
- **Maturity, maintenance, and risk** — first release date, release cadence, bus factor, license, recent security advisories, project health signals (issue triage, PR throughput).
- **Scope creep risk** — Nextcloud and SOGo are full groupware suites; for a calendar-only need, is the operational overhead justified, or is a focused CalDAV server a better fit?

### What I want at the end

1. **Side-by-side comparison table** on the axes above. Be specific. "Supports recurring events" is too vague; "Supports RRULE including BYSETPOS, with known issues on EXDATE in iOS native client per [issue link]" is the bar.
2. **Per-option deep dive.** For each candidate that survives the exclusion filters: what it is, what it gets right, what it gets wrong, the kind of user/setup it fits best, and the kind it doesn't. Include a representative `docker-compose` or install snippet if one is canonical for the project.
3. **Recommendation logic.** Not a single answer. A decision tree: "if you want X (e.g., minimal footprint, calendar-only, no PHP), pick A; if you want Y (e.g., contacts + files + calendar in one), pick B." Be honest about where the answer is genuinely close, and call out which option you'd pick for a single-user iPhone-first setup if forced to choose one.
4. **What could change the answer.** Emerging projects, pending features, or risks (license changes, maintainer burnout, iOS CalDAV behavior changes) that could flip the recommendation in 1–2 years.
5. **Pre-deployment gotcha list.** Anything I should know *before* I start the install: known iOS sync quirks, reverse-proxy header requirements, DB backup ordering, TLS/cert expectations, default-credential issues. This is the section I most want to not have to discover the hard way.

### Output format

Markdown document with the five items above as `##` section headings. Pipe tables for the side-by-side. Concrete details over vague qualitatives wherever possible — "iOS sync is reliable" is less useful than "iOS native Calendar app syncs via CalDAV; push is polling-based at iOS-default ~15 min intervals; recurring events with exceptions occasionally lose the exception per [linked issue]".

Cite specific claims inline.

End with `## References`. Real, verifiable links only, with a one-sentence note for each. **For every option, cite at least one independent source** — not the project's own README or marketing. Independent sources include: r/selfhosted threads with deployment reports, blog posts from people running the tool in production, GitHub issues describing real-world bugs, third-party comparison reviews. Project documentation is fine for capability claims but should not be the only source on reliability, iOS sync quality, or maintenance health. **Omit any source you are uncertain about — do not fabricate URLs, issue numbers, or author names.**
