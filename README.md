# Watchlist

A personal global watchlist for movies and TV shows across streaming services. Built with Ruby on Rails 8, Tailwind CSS, and TMDB for rich metadata.

## Features

- 🎬 Track movies and TV shows across Netflix, Max, Disney+, Hulu, Prime Video, Apple TV+, Peacock, Paramount+, and more
- 🔍 Auto-fetch rich metadata (poster, synopsis, rating, runtime, genres) from TMDB
- 🔗 Auto-detect streaming service from URL
- ✅ Two statuses: **Want to Watch** and **Watched**
- 📱 Responsive card-based UI with poster art
- 🤖 Add items via Telegram by sending a streaming link or movie title
- 🔒 Basic HTTP auth to keep it private

## Quick Start

### Prerequisites

- Ruby 3.3+
- Bundler (`gem install bundler`)
- A free [TMDB API key](https://www.themoviedb.org/settings/api)

### Setup

```bash
git clone https://github.com/darbot5000/watchlist.git
cd watchlist
bin/setup
```

`bin/setup` will:
- Install gems
- Copy `.env.example` → `.env`
- Create and migrate the database

### Configure

Edit `.env` and fill in your values:

```env
AUTH_USERNAME=admin
AUTH_PASSWORD=your_secure_password

# Required for rich metadata
TMDB_API_KEY=your_tmdb_api_key

# Optional - for Telegram integration
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_WEBHOOK_SECRET=any_random_string
```

### Run

```bash
bin/dev
```

Open [http://localhost:3000](http://localhost:3000) and log in with your credentials.

### Seed sample data (optional)

```bash
bin/rails db:seed
```

## Telegram Integration

To add items to your watchlist by sending messages to a Telegram bot:

1. Create a bot with [@BotFather](https://t.me/BotFather) and get the token
2. Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_WEBHOOK_SECRET` in `.env`
3. Register the webhook with Telegram:

```bash
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app-url.com/telegram/webhook",
    "secret_token": "your_webhook_secret"
  }'
```

Then send messages to your bot:
- **Streaming URL**: `https://www.netflix.com/title/dune` — auto-detects service and title
- **Plain title**: `The Dark Knight` — looks it up on TMDB

## Streaming Service Auto-Detection

Supported services detected from URL:

| Service | Domain |
|---|---|
| Netflix | netflix.com |
| Max | max.com, hbo.com |
| Disney+ | disneyplus.com |
| Hulu | hulu.com |
| Prime Video | primevideo.com, amazon.com |
| Apple TV+ | tv.apple.com |
| Peacock | peacocktv.com |
| Paramount+ | paramountplus.com |
| MUBI | mubi.com |
| Shudder | shudder.com |
| YouTube | youtube.com |

## Tech Stack

- **Ruby on Rails 8** — web framework
- **SQLite** — database (easy local dev, swap for PostgreSQL in production)
- **Tailwind CSS** — styling
- **Hotwire (Turbo + Stimulus)** — reactive UI without a JS framework
- **TMDB API** — movie/TV metadata
- **HTTParty** — HTTP client for TMDB
- **Propshaft** — asset pipeline
