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

## License

MIT
