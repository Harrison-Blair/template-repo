I want a comparative analysis of **self-hostable applications for backing up and (optionally) managing iPhone photos and videos**, as a private alternative to Google Photos / iCloud Photos.

**Decision context**: I want my iPhone's photos and videos to back up automatically to my own infrastructure rather than to a cloud provider. I have two relevant pieces of hardware:
- A dedicated always-on Linux host (capable of running Docker workloads, modest CPU/RAM — assume mid-range mini-PC class unless I say otherwise).
- A separate OpenMediaVault (OMV) NAS with 3 TB of usable storage in RAID5, EXT4. This is where the actual photo data should live long-term.

The architectural question of *where the application itself runs* (on the host with the photo library on NFS/SMB-mounted NAS storage, vs. running the application on the NAS itself in Docker via OMV's container support) is itself something I want this report to address per option, since some self-hosted photo tools have well-known issues with remote-mounted libraries (sqlite/database locking on NFS, file-watcher reliability, thumbnail-generation IO). Do not assume one architecture; evaluate both.

I use an iPhone daily, so iOS is the primary capture device. I want a web UI for desktop access. This is a single-user setup; no family/shared libraries needed (but note any option that handles that poorly in case I later add a partner). I do not currently have a large existing photo library to migrate — assume a fresh start with whatever I can export from iCloud / iPhone Photos, plus ongoing daily capture going forward.

The goal of this report is to let me confidently pick one option to deploy, not just to learn the landscape.

**Audience**: Me — technically literate, comfortable with Docker/`docker compose`, comfortable editing config files, but not a sysadmin by trade. Assume Linux/self-hosting fluency. Explain photo-management-specific concepts (HEIC/HEVC handling, ML embedding pipelines, library-vs-album semantics, sidecar files, original-file immutability) when they are load-bearing for the comparison.

**Depth**: Thorough. This should support a real deployment decision and surface gotchas before I install and start backing up irreplaceable photos to it.

**Time scope**: Current state of each option as of 2026. The self-hosted photo space is moving fast (Immich in particular). Strongly prioritize sources from 2024-onward; flag major changes (rewrites, license changes, breaking schema migrations, project forks, abandonment) in the last 18 months. If a project's last meaningful release is older than 12 months, say so explicitly.

**Geographic / regulatory scope**: Not applicable — personal use, no compliance requirements.

**Scope of "backup"** [DEFAULT — confirm]: I am treating this as both **backup** (canonical copy of every photo and video, lossless, recoverable to original files even if the application disappears) **and** **management** (browsing, search, albums, faces). If a strong option exists that is purely backup with no management UI (e.g., something rsync-like), include it but say so. The bar for "backup" specifically: I should be able to walk away from the application tomorrow and still have my originals as plain files in a sane folder structure on the NAS.

**Exclusions**:
- No hosted/SaaS services (iCloud Photos, Google Photos, Amazon Photos, Ente cloud-hosted tier, etc.) — must be self-hostable on my own hardware.
- No Android-only or desktop-only ecosystems — first-class iOS auto-upload is mandatory.
- No options that require a paid license for personal/single-user self-hosting (note this if it applies; do not include them in the final ranking).
- Skip vendor marketing pages and SEO listicles. Prefer project documentation, GitHub repos, r/selfhosted threads with substantive deployment reports, and independent blog posts from people running the tool against a real photo library at non-trivial scale.
- No LLM-generated comparison articles.

### Candidates to evaluate

Cover at minimum the following, and add any other actively-maintained self-hostable photo backup/management tool with a working iOS auto-upload story:

- **Immich**
- **PhotoPrism**
- **Nextcloud Photos** (and the Nextcloud iOS app's auto-upload behavior)
- **Ente** (self-hosted)
- **LibrePhotos**
- **PhotoSync** as a uploader (paired with a backend like SFTP/WebDAV/SMB) — only if it makes sense as a "just backup" path
- Any newer Rust/Go-stack photo manager that has emerged recently and is plausibly stable enough for trusted-of-the-only-copy use

If a project is effectively unmaintained (no commits in >12 months, archived repo, unanswered security issues), say so explicitly and exclude from the final recommendation, but mention briefly so I know it was considered.

### Comparison axes

- **iOS auto-upload reliability** — this is the make-or-break axis. How does each option get photos off the iPhone? Native app with iOS background-upload entitlement, generic WebDAV/SMB upload via a third-party app like PhotoSync, or browser upload? How reliable is background upload in practice (battery impact, iOS killing the app, photos taken while offline syncing later)? Are there known issues with HEIC, Live Photos, Motion Photos, slow-mo / 4K60 video, Burst mode, RAW (ProRAW), depth/portrait metadata, or location stripping?
- **On-disk format and recoverability** — when the app stores my photos on the NAS, what does the directory structure look like? Are originals stored unmodified (bit-for-bit identical to what came off the phone), or are they re-encoded? Is metadata stored in sidecar files, in a database, or both? If the application's database is destroyed but the file tree on the NAS survives, can I still browse my photos as files? This is the "can I walk away" test.
- **Remote storage / NAS architecture** — how does each option behave when the photo library sits on remote-mounted storage (NFS, SMB) vs. local disk? Known issues with sqlite on NFS, thumbnail IO patterns, file-watcher reliability over remote mounts. For each option, recommend: run the app on the host with NAS-mounted library, run the app on the NAS itself (OMV Docker), or other.
- **Storage efficiency** — deduplication (same photo uploaded twice), compression, thumbnail sizing strategy, machine-learning embedding storage size. Rough rule of thumb for "library size on disk vs. raw photo bytes" for each option.
- **Library size handling** — how does each option scale to ~3 TB and ~100k+ items? Initial-import time, memory pressure during ML pass, query latency on the web UI. Note any reported tipping points where users start hitting trouble.
- **ML / management features** — face recognition (and how the model is shipped — local CLIP/InsightFace? cloud?), object/scene search, OCR on text in photos, duplicate detection, automatic albums, map view, search-by-natural-language. Be honest about which of these work well vs. work poorly vs. don't exist per option.
- **Web UI quality** — browsing speed, timeline view, album management, sharing, mobile-browser usability, keyboard shortcuts.
- **Mobile app quality (iOS)** — does the project ship its own iOS app? Is it on the App Store or only via TestFlight / sideload? What does it do beyond upload — browse, share, free up space on the device?
- **Deployment complexity** — Docker image quality, official `docker-compose.yml`, dependencies (DB, Redis, ML services, reverse proxy), GPU optionality for ML, CPU-only viability, RAM at idle vs. during ML pass.
- **Backup story** — given that the photo library *is* on the NAS and the NAS *is* the storage tier, what does an additional backup of this system look like? What needs to be backed up beyond the photo files (DB dumps, config, ML embeddings, faces model)? Are restore procedures documented? Any known footguns (e.g., DB and file backups must be atomic, ML embeddings must be regenerated on restore)?
- **Migration / export** — can I get my photos *out* later if I want to switch tools? Is there an export path beyond "the files were already on disk"? Especially: face tagging, albums, captions — are those portable, or trapped in the application's DB?
- **Maturity, maintenance, and risk** — first release, release cadence, bus factor, license, recent security advisories, project health signals. For Immich specifically: it had an explicit "not stable, do not trust as your only backup" warning in its README for a long time — what is the project's current self-stated stability posture, and what is the community's lived experience?
- **Single-source-of-truth risk** — if I trust this application as the *only* copy of irreplaceable photos, what's the failure mode that bites me? Schema migrations that lose data, library scans that delete originals on rename, sync conflicts, etc. Real reported incidents preferred over theoretical risks.

### What I want at the end

1. **Side-by-side comparison table** on the axes above. Be specific. "Good iOS upload" is too vague; "Native iOS app on App Store, background upload works reliably per [linked deployment reports], known issue with Live Photos motion component being dropped in HEIC mode per [issue link]" is the bar.
2. **Per-option deep dive.** For each surviving candidate: what it is, what it gets right, what it gets wrong, the kind of user it fits, the kind it doesn't. Include a representative `docker-compose` snippet if one is canonical, and a recommended host-vs-NAS deployment topology.
3. **Recommendation logic.** Not a single answer. A decision tree: "if you want X (e.g., minimal trust surface, files-on-disk recoverability, no ML), pick A; if you want Y (e.g., Google-Photos-like search and faces), pick B." Be honest about where the answer is genuinely close. If forced to pick one for a single iPhone user starting fresh with a 3 TB NAS, say which and why.
4. **Belt-and-suspenders backup pattern.** Regardless of which app I pick, what is a sensible second-layer backup of the photo library itself off the NAS (e.g., to encrypted off-site storage)? Brief — one paragraph, not a deep dive — but enough that I don't end up with my "self-hosted backup" being my only copy.
5. **What could change the answer.** Emerging projects, pending features, or risks (license changes, App Store policy, iOS background-upload API changes) that could flip the recommendation in 1–2 years.
6. **Pre-deployment gotcha list.** Anything I should know *before* I start the install: known iOS upload quirks, NFS/SMB pitfalls for the chosen library backend, EXT4 vs. other FS considerations for a 3 TB photo library, default-credential issues, schema-migration hazards, GPU/ML model download size and timing.

### Output format

Markdown document with the six items above as `##` section headings. Pipe tables for the side-by-side. Concrete details over vague qualitatives wherever possible — "ML is good" is less useful than "Ships CLIP ViT-B/32 by default; ~1.5 GB model download on first start; ~40 photos/sec on CPU on a Ryzen 5600 per [linked report]".

Cite specific claims inline.

End with `## References`. Real, verifiable links only, with a one-sentence note for each. **For every option, cite at least one independent source** — not the project's own README. Independent sources include: r/selfhosted threads with deployment reports at scale, blog posts from people running the tool on >50k items, GitHub issues describing real-world data-loss or sync incidents, third-party comparison reviews. Project documentation is fine for capability claims but should not be the only source on reliability, iOS upload quality, or "is this safe as my only copy" judgments. **Omit any source you are uncertain about — do not fabricate URLs, issue numbers, or author names.**
