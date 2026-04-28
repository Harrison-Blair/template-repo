I want a deep research report on the **landscape of self-hostable tools and services worth running in 2026**, organized for three overlapping use cases: everyday personal life, professional software development, and hobby/side-project development.

**Audience**: an individual just getting into self-hosting. Comfortable with Docker and docker-compose, not yet experienced running production-grade services. Background is software development, not sysadmin / SRE.
**Depth**: thorough survey, not exhaustive per-tool deep-dive. The report is a discovery doc — it should give me enough to shortlist 5–15 tools to investigate further, not a 200-page bible.
**Time scope**: current state as of 2026. For each tool, note last release date and maintainer activity in the last 12 months. Flag projects that have stalled or been abandoned. Historical context (e.g., why a tool was created) only when it explains current trade-offs.
**Ecosystem / platform scope**: my deployment target is **OpenMediaVault (OMV)** with `omv-extras` and the OMV `compose` plugin running on a Linux home server. Recommendations must be deployable as a single Docker container or a docker-compose stack on that host. Tools that require Kubernetes, Nomad, or heavier orchestration are out of scope. Tools that need a separate VM (rather than a container) should be flagged explicitly. ARM64 support is a nice-to-have, not a requirement — assume amd64. Windows-only or macOS-only tools are out of scope unless they have a first-class Linux container path.
**Project context**: this is **greenfield**. I'm building a self-hosted stack from scratch, not migrating from existing SaaS subscriptions. The report should help me decide what's worth standing up at all, in roughly what order, and where to start as a beginner.
**Exclusions**:
- SaaS-only or "open core but the useful features are cloud-only" products. Self-hosting must be a first-class supported deployment, not a hobbled community edition.
- Paid-only / enterprise-licensed tools. Free-tier-with-self-host is fine if the free tier is genuinely usable for an individual.
- Abandoned projects (no commits in 18+ months) unless they remain the de-facto category leader with no live alternative.
- Vendor marketing pages, AI-generated "top 10" listicles, SEO blog spam, low-quality Medium posts.
- Tools that require a paid license to remove watermarks, paywall basic features, or phone home.

### What I want to come away understanding

For each of the three sections below, I want to know **what categories of needs are well-served by self-hosted tools today**, **which specific projects lead each category**, and **what the trade-offs of self-hosting actually are** (hardware, time, security exposure, "do I really need this"). I should finish the report with a clear sense of where self-hosting is genuinely the better choice versus where it's a hobby tax.

### Structure

Produce three top-level sections, each organized as a category survey. For every tool surfaced, give:

- **What it replaces** (the SaaS / commercial product whose itch it scratches)
- **License**
- **Hosting complexity** (single container / docker-compose stack / requires Kubernetes / requires reverse proxy + auth / requires external DB)
- **Resource footprint** (rough RAM / CPU / disk; whether it runs on a Raspberry Pi-class device)
- **Maturity signal** (last release, contributor count, stars trend, production users)
- **Notable gotchas** (footguns, brittle upgrade paths, data-loss risk, mobile-app quality if relevant)
- **Verdict**: category leader / strong contender / niche pick / interesting but immature

Use pipe tables for the per-category roundups. For each category, name a clear leader and 1–3 alternatives.

#### 1. Everyday personal life

Cover at minimum these categories — add others if there's a strong case:

- **File sync and backup** (Dropbox / iCloud Drive replacements)
- **Photo management and backup** (Google Photos / iCloud Photos replacements; iOS + Android client quality matters)
- **Notes, knowledge management, and bookmarks** (Notion / Evernote / Pocket replacements)
- **Password and secret management** (1Password / LastPass replacements)
- **Email** — flag honestly whether self-hosting outbound email in 2026 is realistic for an individual, or whether the answer is "use a hosted provider and self-host only IMAP / webmail / aliasing"
- **Calendar and contacts** (Google / iCloud replacements; CalDAV / CardDAV ecosystem)
- **RSS and read-it-later**
- **Media servers** (Plex / Jellyfin / Emby; *arr stack is in scope; legal grey areas should be noted neutrally, not avoided)
- **Smart home hub** (Home Assistant and the surrounding ecosystem)
- **Personal dashboards / start pages**
- **Document scanning, OCR, and personal document archive** (paperless-ngx and peers)
- **Recipes, finance tracking, fitness tracking, journaling** — survey-level, not exhaustive

#### 2. Professional software development (work)

Tools an individual or small team would self-host to support real day-job work. Cover:

- **Git hosting and code review** (GitHub / GitLab Cloud replacements: Gitea, Forgejo, GitLab CE, etc.)
- **CI / CD runners** (self-hosted GitHub Actions runners, Forgejo Actions, Drone, Woodpecker, Buildkite agents)
- **Container registries** (Harbor, Distribution, Forgejo's built-in, etc.)
- **Artifact / package registries** (npm, PyPI, Maven, NuGet — Verdaccio, Nexus, Artifactory CE, Forgejo packages)
- **Secrets management** (Vault, Infisical, OpenBao, Bitwarden for shared team secrets)
- **Observability stack** (Prometheus + Grafana + Loki + Tempo / OpenTelemetry collector; SigNoz, Uptrace, Coroot as integrated options)
- **Error tracking** (GlitchTip, self-hosted Sentry)
- **Issue tracking and project management** (Linear / Jira replacements: Plane, OpenProject, Forgejo issues, Vikunja)
- **Documentation and wikis** (Confluence replacements: BookStack, Outline, Wiki.js)
- **Internal chat** (Slack replacements: Mattermost, Rocket.Chat, Zulip)
- **Identity and SSO** for the above (Authentik, Keycloak, Zitadel, Pocket ID)
- **Reverse proxy + TLS** as the connective tissue (Caddy, Traefik, nginx-proxy-manager)

For this section especially, be opinionated about **which categories are mature enough to bet a team's productivity on** versus **which categories the self-hosted options are still meaningfully behind the SaaS leader**. A team's time is expensive — surface where the self-hosting tax is real.

#### 3. Hobby / side-project development

Same conceptual list as the work section, scoped down to a solo developer or a small group of friends. Emphasize:

- **The "lazy stack"** — the smallest set of self-hosted tools that lets a solo dev have private git + CI + a place to deploy + observability without becoming an unpaid SRE.
- **PaaS-style self-hosted platforms**: Coolify, Dokku, CapRover, Caprover, Kamal, Coolify, Dokploy — what each is good at, where they fall over, who should use which.
- **Dev environment / coding workspaces**: code-server, Coder, Gitpod self-hosted, devpod.
- **Tunneling and remote access** for hobby projects you want reachable from your phone: Tailscale (note: control plane is SaaS — flag this), Headscale, Cloudflare Tunnel (note: relies on Cloudflare), Pangolin, plain WireGuard.
- **One-click app catalogues** for hobbyists: Umbrel, CasaOS, YunoHost, Cosmos — useful starting points or training-wheel traps? (Note: my host is OMV, so frame these as alternatives I rejected vs. things to layer on, not things to install over my OS.)

#### 4. Self-hosted AI / LLM tooling

Treat this as a first-class category, not an appendix. Cover:

- **Local model runtimes**: Ollama, llama.cpp, LM Studio (insofar as it has a self-hostable server mode), vLLM, LocalAI, Text Generation WebUI. Cover their differences in throughput, quantization support, batching, OpenAI-compatible API surface, and ease of deployment.
- **Web UIs and chat frontends**: Open WebUI, LibreChat, AnythingLLM, others. Compare on multi-user support, auth, RAG features, tool/function calling support, mobile UX.
- **Coding assistants** that work with a self-hosted backend: Continue.dev, Tabby, aider, Cline / Roo Code, OpenHands, Zed's local-model support, anything else worth naming. For each, what does the user run locally and what does the backend need?
- **Image and media generation**: ComfyUI, SD.Next, Automatic1111, Fooocus; voice models (Whisper, Piper, Coqui / equivalents); video / TTS where the self-hosted story is real.
- **Vector stores and embedding infrastructure**: Qdrant, Weaviate, Chroma, Milvus, pgvector. When does an individual actually need one of these vs. lighter alternatives?
- **Agent / RAG / workflow platforms**: n8n (for AI workflows), Flowise, LangFlow, Dify — what each is good at, where they fall over.
- **Hardware reality check.** This is the most important part of this section for me. My host is an OMV NAS-class machine — likely amd64 CPU, lots of disk, modest RAM, no dedicated GPU. Be honest about:
  - What useful things can I actually run CPU-only or with iGPU offload? (Whisper small models? 7B-class LLMs at usable speeds? Embeddings only?)
  - What's the cheapest realistic GPU path (used 3060 12GB? 4060 Ti 16GB? Ryzen AI / Strix Halo?), and what does that unlock?
  - Where is "just use Claude / OpenAI's API" still the right answer in 2026, and where has self-hosted closed the gap?
- **Privacy / data-residency angle.** What workloads are actually worth self-hosting for the privacy benefit (medical/legal docs, journals, personal RAG over email/notes) vs. things where API providers are fine.

### 5. Cross-cutting analysis

After the four sections above, include:

1. **The honest case against self-hosting**: where SaaS still wins on cost-of-time, reliability, security, mobile experience, or "your spouse / coworkers won't tolerate the downtime". Be specific — name the categories where I should *not* self-host even though I could.
2. **Backup and disaster-recovery story** for a self-hosted stack as a whole (restic, Kopia, Borg, Duplicati, off-site strategies). Treat this as load-bearing — the most common self-hosting failure is "ran for two years, then a disk died and there were no usable backups." Note OMV-specific options (the SnapRAID + mergerfs pattern, OMV's built-in rsync/borg plugins) where relevant.
3. **Security posture** for someone exposing services to the internet: reverse-proxy-only-on-LAN-plus-VPN vs public exposure with auth, fail2ban / CrowdSec, TLS automation, the realistic threat model for a solo operator.
4. **Effort budget**: rough hours-per-month maintenance burden for a "small" (3–5 services), "medium" (10–15 services), and "large" (30+ services) self-hosted footprint, based on community-reported experience.
5. **A suggested onboarding order for a greenfield beginner.** Given everything above, what 3–5 services should I stand up *first* to build operational muscle (reverse proxy + TLS, backups, identity, one "real" workload)? What should I deliberately defer until later? This is the most actionable thing the report can give me.

### Output format

Markdown document with the five top-level sections (`## 1. Everyday personal life`, `## 2. Professional software development`, `## 3. Hobby / side-project development`, `## 4. Self-hosted AI / LLM tooling`, `## 5. Cross-cutting analysis`). Use `###` subheadings for each category. Use pipe tables for per-category tool roundups. Use fenced code blocks only for compose snippets or config samples that meaningfully clarify a point — not for filler.

Do not pad. If a category has one obvious answer, say so in two sentences and move on.

Cite specific claims inline (`[source name](url)` is fine).

End with `## References`. Every reference must be a real, verifiable link with a one-sentence note explaining what it is and why it's cited. Prefer **primary sources**: project repositories (GitHub / Codeberg / GitLab), official docs, maintainer-written posts, conference talks, well-regarded community resources (e.g., [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted), the r/selfhosted wiki where it's curated rather than anecdotal). Independent third-party benchmarks and write-ups from operators running these tools at scale are valuable. Vendor blog posts and "top 10" listicles are not. **Omit any source you are uncertain about — do not fabricate URLs, repo names, or author names.** If a claim cannot be confidently sourced, soften the claim rather than invent a citation.
