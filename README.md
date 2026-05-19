# w_popularity

Track audience growth across social platforms. Daily snapshots → time-series KPIs (velocity, CAGR, engagement) → Next.js dashboard.

## Stack

- **Frontend** `frontend/` — Next.js + Recharts, auth via [auth.marketmaker.cc](https://auth.marketmaker.cc)
- **Backend** `backend/` — Go (gin, pgx), API + cron scheduler, Postgres job queue
- **Shared** `shared/` — Go module: `Parser` interface, snapshot types
- **Parsers** `parsers/<platform>/` — one Go module per platform, per-platform best-fit (API → HTML → camoufox fallback)
- **DB** — PostgreSQL, append-only snapshots, BRIN(ts), SQL views for KPIs

All subprojects are git submodules under [github.com/suenot](https://github.com/suenot).

## Layout

```
w_popularity/
├── go.work               # Go multi-module workspace
├── docker-compose.yml
├── socials.md
├── frontend/             # submodule: w-popularity-frontend
├── backend/              # submodule: w-popularity-backend
├── shared/               # submodule: w-popularity-shared
├── camoufox/             # submodule: w-popularity-camoufox  (stealth HTTP wrapper)
└── parsers/
    ├── youtube/          # submodule: w-popularity-parser-youtube
    ├── x/                # submodule: w-popularity-parser-x
    ├── telegram/         # submodule: w-popularity-parser-telegram
    ├── facebook/         # submodule: w-popularity-parser-facebook
    ├── instagram/        # submodule: w-popularity-parser-instagram
    ├── linkedin/         # submodule: w-popularity-parser-linkedin
    ├── habr/             # submodule: w-popularity-parser-habr
    ├── stackoverflow/    # submodule: w-popularity-parser-stackoverflow
    ├── tbank-pulse/      # submodule: w-popularity-parser-tbank-pulse
    └── smartlab/         # submodule: w-popularity-parser-smartlab
```

## Quick start

```bash
git clone --recurse-submodules git@github.com:suenot/w-popularity.git
cd w-popularity
cp .env.example .env
docker compose up -d postgres
docker compose up backend frontend
```

## KPIs computed

Per channel daily snapshot of: followers, posts count, total likes, total views, total comments.

Derived metrics:
- Δ% over 7d / 30d / 90d / 365d
- CAGR (compound annual growth rate)
- WoW / MoM / YoY
- Velocity (subs/day, rolling 7d & 28d)
- Acceleration (Δvelocity, viral inflection)
- Engagement rate per post (avg last 20)
- View-to-sub ratio (YouTube)
- Post cadence + std-dev
- Virality index (top post / median)
- Net new subs per post (7d window)

Cross-channel: total reach, platform mix %, HHI concentration.

## Parser strategies

| Platform | Primary | Fallback |
|---|---|---|
| YouTube | YouTube Data API v3 | yt-dlp |
| Telegram | MTProto / channel preview HTML | camoufox |
| X | API v2 / Nitter | camoufox |
| Facebook | Graph API | camoufox |
| Instagram | Graph API (business) | camoufox |
| LinkedIn | HTML scrape | camoufox |
| Habr | RSS + HTML | HTTP only |
| Stack Overflow | Stack Exchange API | — |
| T-Bank Pulse | Public JSON | camoufox |
| Smart-Lab | HTML scrape | camoufox |

## camoufox (stealth scraping)

LinkedIn and Facebook personal-profile pages don't expose follower counts
to anonymous HTTP and reject most server-side bot fingerprints. The
`camoufox/` submodule is a FastAPI wrapper around the
[camoufox](https://github.com/daijro/camoufox) stealth Firefox fork that
parsers call via `POST /fetch` to get fully-rendered, post-login HTML.

### One-time login per platform

The container persists cookies per-profile under `data/camoufox-profiles/`.
You log in once interactively via VNC; production fetches reuse the saved
profile silently.

```bash
# 1. build the image
docker compose --profile scraping build camoufox

# 2. LinkedIn login — run headed with VNC exposed
docker compose --profile scraping run --rm -p 5900:5900 camoufox \
    python login_helper.py linkedin https://www.linkedin.com/login

# 3. on macOS, attach to the VNC session
open vnc://localhost:5900
# complete the login (handle 2FA / captchas as you would in a real browser),
# then close the browser window — the helper saves cookies to
# data/camoufox-profiles/linkedin/.

# 4. same for Facebook
docker compose --profile scraping run --rm -p 5900:5900 camoufox \
    python login_helper.py facebook https://www.facebook.com/login
```

### Production usage

```bash
docker compose --profile scraping up -d camoufox backend frontend postgres
curl -sf http://localhost:3001/healthz   # {"ok":true}
```

The `CAMOUFOX_URL` env var (defaulted to `http://camoufox:3000` in
`.env.example`) is read by the LinkedIn and Facebook parsers. When set,
those parsers POST target URLs to the wrapper and parse the returned HTML
through their existing extractors.

## License

MIT
