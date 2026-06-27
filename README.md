# Claude Power Skills ⚡

> **19 powerful, original [Claude Code](https://claude.ai/code) skills** — reel & video intelligence, a heavy-prompt engineering system, deep code audits, session save/restore, and more. One command each.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Powered by Claude Code](https://img.shields.io/badge/for-Claude%20Code-orange)](https://claude.ai/code)
[![Skills](https://img.shields.io/badge/skills-19-brightgreen)]()

These aren't link lists or thin wrappers around the built-ins. They're real, battle-tested slash-command skills — used daily, then cleaned up and packaged so you can drop them straight into your own Claude Code setup.

---

## Install

Each skill is a self-contained folder under [`skills/`](skills/). Copy the ones you want into your Claude Code skills directory:

```bash
# everything
cp -r skills/* ~/.claude/skills/

# or just one
cp -r skills/reel ~/.claude/skills/
```

Then run it inside Claude Code: `/reel`, `/heavy`, `/sanity-check`, `/what-breaks` …

---

## The skills

### 🔍 Intelligence — multi-tool analysis pipelines
| Skill | What it does |
|---|---|
| `/reel` | Deep-analyze an Instagram/TikTok reel — download, transcribe, extract frames, scrape comments, research → a replication strategy. `-h` full pipeline · `-l` fast visual-only. |
| `/yt-tran` | YouTube video intelligence — transcript + key frames + top comments → an **action report**, not a transcript dump. `-h` deep · `-l` fast. |
| `/biz-validate` | Validate a business idea — problem research, market sizing, competition, persona simulation → a go/no-go verdict. |
| `/clone-website` | Reverse-engineer and rebuild any site, section by section, with parallel builder agents. |

### ✍️ Prompt engineering — a complete heavy-prompt system
| Skill | What it does |
|---|---|
| `/heavy` | Launch a pre-engineered "heavy prompt" from your library and run it in-session. |
| `/heavy-build` | Author a new heavy prompt — interview → decompose into phases → write the anchored spec + guardrails. |
| `/heavy-review` | Adversarially review a heavy prompt for logic gaps, safety, resumability, and output-spec correctness → PASS / NEEDS-FIX. |
| `/make-prompt` | Craft a production-grade prompt for any target — LLM, image-gen, or system/agent — using the right best practices. |

### ✅ Code quality — audits with teeth
| Skill | What it does |
|---|---|
| `/sanity-check` | Post-implementation audit — security, logic, edge cases, stack-specific checks → PASS/FAIL with severity tiers. |
| `/double-check` | Hunt defects across five lenses, fix what's safe, verify → a confidence rating out of 10. |
| `/what-breaks` | Pre-mortem — assume the plan already failed and hunt the reasons, ranked by likelihood × impact, with mitigations. |
| `/orient` | Drop into an unfamiliar project and get oriented fast — what it is, the stack, entry points, where to start. |
| `/ship` | Pre-deploy gate → deploy → smoke-test the live URL, in one pass. |

### 💾 Session & workflow — never lose your place
| Skill | What it does |
|---|---|
| `/save-session` | Save your session state to project memory so it's discoverable later. |
| `/catch-up` | Cross-project command center — scan every project's saved state into one dashboard of open work. |
| `/overnight` | Schedule the current task to run unattended overnight (headless), isolated on a branch, results surfaced next morning. |

### 🛠️ Utility
| Skill | What it does |
|---|---|
| `/braindump` | Turn a messy voice ramble into clean structured output — spec, tasks, outline, or decision. |
| `/explain-for-grandma` | Re-explain the previous answer in plain, beginner-friendly language. |
| `/monitor-claude` | Read-only Claude process health check — active sessions, anomalies, kill commands (bundled script). |

---

## Prerequisites

Most skills work out of the box. A few need external tools — each `SKILL.md` documents its own:

- **`/reel`, `/yt-tran`** — [yt-dlp](https://github.com/yt-dlp/yt-dlp), [ffmpeg](https://ffmpeg.org), and [faster-whisper](https://github.com/SYSTRAN/faster-whisper) (GPU-accelerated with automatic CPU fallback). Optional: a Firecrawl/Tavily/Playwright MCP for comments and web research.
- **`/biz-validate`, `/clone-website`** — a search/scrape MCP ([Firecrawl](https://firecrawl.dev) or [Tavily](https://tavily.com)) and/or [Playwright](https://playwright.dev).
- **`/overnight`, `/monitor-claude`** — Windows (Task Scheduler / PowerShell); cross-platform adaptation notes are inside each skill.

---

## Credits

Built by **David Vrba**. These skills grew out of **[DukOS](https://github.com/david-vrba/dukos)** — an open-source, autonomous Claude Code agent system. Several use [yt-dlp](https://github.com/yt-dlp/yt-dlp), [Whisper](https://github.com/openai/whisper)/[faster-whisper](https://github.com/SYSTRAN/faster-whisper), [ffmpeg](https://ffmpeg.org), [Firecrawl](https://firecrawl.dev), [Tavily](https://tavily.com), and [Playwright](https://playwright.dev) under the hood — credit to those projects.

## Contributing

Found a bug, improved a skill, or have one to add? PRs welcome.

## License

MIT — use them, fork them, build on them. See [LICENSE](LICENSE).
