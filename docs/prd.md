# Product Requirements Document — Watchlist

**Product:** Watchlist  
**Version:** 1.0  
**Author:** Product  
**Date:** March 9, 2026  
**Status:** Draft

---

## 1. Overview

Watchlist is a personal, unified tracking service for movies and TV shows across all streaming platforms and traditional viewing mediums (broadcast TV, movie theaters). The core promise is simple: one place to capture everything you want to watch, regardless of where it lives.

The product exists because streaming is fragmented. The average household subscribes to 4–6 streaming services. Finding something to watch means opening multiple apps, scrolling through different interfaces, and relying on your memory for things people recommended last week. Watchlist kills that friction.

---

## 2. Problem

People want to watch things. They find out about things through trailers, articles, friend recommendations, social posts, ads, and word of mouth. Then they forget. Or they remember a show but can't recall which service it's on. Or they lose the tweet that linked to that documentary.

The discovery moment and the watching moment rarely coincide. Watchlist bridges that gap.

**What we are NOT building:** A social product. A recommendations engine. A streaming aggregator. This is a personal tool — fast, private, and focused on capture and retrieval.

---

## 3. Goals

- Let a user capture any show or movie in under 10 seconds
- Surface rich metadata so the user remembers why they added something
- Make search powerful enough that a user can find an item even with incomplete information
- Support all viewing surfaces: streaming, broadcast TV, movie theaters
- Stay fast, private, and simple — this is a calm product

---

## 4. Non-Goals

- Social features (sharing, following, ratings for others)
- Streaming service recommendations or "what to watch next" AI
- Managing a watch history beyond simple Watched / Want to Watch statuses
- Native mobile apps (v1 is web-first with Telegram as the capture layer)

---

## 5. Users

**Primary user:** A single person (or household) managing their own watch queue. Not a team. Not a social graph.

This is a single-tenant product with basic auth. You deploy it. You use it. Future versions may support multi-user households, but v1 is explicitly personal.

---

## 6. Core Features

### 6.1 Authentication

- Basic HTTP authentication with a single set of credentials (username + password)
- Configured via environment variables
- No sign-up flow; no user management UI
- Private by default — nothing is public

### 6.2 Watchlist (The List)

The primary view is a list of items the user wants to watch or has watched.

**Item states:**
- **Want to Watch** — captured, not yet watched
- **Watched** — completed

Items can be filtered by state. Default view shows "Want to Watch" items.

**Item types:**
- Movie (theatrical, streaming, direct-to-video)
- TV show / series
- TV episode (optional in v1 — episodes can be tracked at the show level)

**Item fields:**
| Field | Description |
|---|---|
| Title | The name of the show or movie |
| Type | Movie or TV Show |
| Poster image | Pulled from TMDB |
| Synopsis | Short description from TMDB |
| Genre(s) | e.g. Drama, Thriller, Comedy |
| Release year | Year of first release |
| Runtime | Length in minutes (movies) or episode count (shows) |
| Rating | TMDB rating |
| Streaming service | Where it's available (may be multiple) |
| Service URL | Direct link to the show/movie on the streaming service |
| Trailer link | Link to official trailer (YouTube or similar) |
| Official website | If available |
| Status | Want to Watch / Watched |
| Added date | When the user added it |
| Notes | Optional free-text field for personal notes |

### 6.3 Add Items

Users should be able to add items via:

1. **URL** — paste a link from a streaming service (Netflix, Max, Disney+, Hulu, Prime Video, Apple TV+, Peacock, Paramount+, MUBI, Shudder, YouTube, etc.). The system auto-detects the service, looks up metadata, and populates the item.

2. **Search by title** — type a title, get TMDB results, pick one.

3. **Natural language / vague search** — powered by an LLM. Examples:
   - "The new show with Jim from The Office"
   - "That dark sci-fi Netflix show everyone was talking about in January"
   - "The Coen Brothers movie with the bowling"

4. **Link to content about the show** — paste a link to:
   - A trailer (YouTube, Vimeo)
   - An article or review (e.g. a Vulture review or NYT piece)
   - A social media post (Twitter/X, Instagram, Reddit thread)
   
   The system should extract the referenced title from the linked content (using LLM if needed), then look it up in TMDB.

5. **Telegram bot** — send a message to the Telegram bot with any of the above (URL, title, natural language, or link). The bot adds the item and confirms.

**Add flow (web):**
1. User pastes a URL or types text in the capture bar
2. System attempts TMDB lookup or LLM resolution
3. If confident: shows a preview card with metadata → user confirms → item added
4. If ambiguous: shows 2–3 candidates → user picks one → item added
5. If no match: user can add manually with a title and optional notes

### 6.4 Search & Discovery (Internal)

Once items are in the list, users should be able to search them. This is the internal list search — not a "what should I watch" engine.

- Full-text search on title, synopsis, genre, notes
- Filter by: status, type (movie/TV), genre, streaming service, year range
- Sort by: date added, title, release year, rating

### 6.5 Rich Metadata

Metadata is the memory layer. The user added something weeks ago — the poster, synopsis, and trailer link are what jogs their memory.

**Primary metadata source:** TMDB (The Movie Database) API

**Fields to pull from TMDB:**
- Poster image (high resolution)
- Backdrop image (optional, for detail view)
- Synopsis / overview
- Genres
- Release date / year
- Runtime (movies) or seasons + episode count (shows)
- Cast (top 5–10)
- Director (movies) / Creator (shows)
- TMDB rating
- Trailer link (YouTube via TMDB videos endpoint)
- Official website (if TMDB provides it)

**Streaming availability:**
- For v1, streaming service is captured at add time (from URL or user selection)
- A future enhancement would use a streaming availability API (e.g. JustWatch) to show all platforms where an item is available

---

## 7. LLM-Powered Search

This is the differentiator. TMDB's standard search handles title lookups. The LLM layer handles everything else.

### 7.1 When LLM is invoked

- User input does not match a known streaming URL pattern
- User input does not produce confident TMDB title search results
- User input is clearly descriptive/contextual rather than a title (e.g. "the one with the maze and the kids")

### 7.2 What the LLM does

**Input:** Raw user text  
**Output:** One or more candidate titles to look up in TMDB

The LLM is used as an intent resolver, not a creative generator. Its job is to translate vague human recall into a TMDB-searchable title.

Example:
- Input: "the new show with Jim from The Office"
- LLM resolves: John Krasinski (Jim Halpert) → suggests recent John Krasinski projects → returns candidate titles
- System looks each candidate up in TMDB → presents results to user

### 7.3 Link parsing

When a URL to an article, trailer, or social post is provided:
1. Fetch page content (or metadata)
2. Pass to LLM with prompt: "What movie or TV show is this content about? Return the title and type."
3. Use returned title for TMDB lookup

### 7.4 LLM constraints

- LLM is used for resolution only — not for generating descriptions, reviews, or recommendations
- Responses must be grounded; no hallucinated titles
- If confidence is low, surface candidates to user rather than auto-adding

---

## 8. Telegram Integration

The Telegram bot is the fastest capture path — you're on your phone, see something, add it in 10 seconds without opening a browser.

**Supported inputs via Telegram:**
- Streaming URL → auto-lookup and add
- Movie/show title → TMDB search, add top result or prompt for disambiguation
- Natural language description → LLM resolution → TMDB → add or prompt
- Link to article/trailer/social post → extract title → TMDB → add

**Bot responses:**
- On success: confirm with title, poster thumbnail, and streaming service
- On ambiguity: show numbered list of candidates, user replies with number to confirm
- On failure: "Couldn't find that one. Try a different title or URL."

**Commands (optional):**
- `/list` — show the last 10 "Want to Watch" items
- `/watched [title]` — mark something as watched

---

## 9. UI/UX Principles

- **Cards, not rows.** The poster image is the primary hook — the list should look like a shelf, not a spreadsheet.
- **Capture first.** The add bar is always visible. Adding something should take under 10 seconds.
- **Metadata on demand.** The card shows title, poster, and service. Click for the full detail view (synopsis, cast, trailer, etc.).
- **No clutter.** No social features, no recommendations, no ads, no badges. One list, two states.
- **Responsive.** Works on desktop and mobile. The Telegram bot covers capture on mobile.

---

## 10. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8 |
| Database | SQLite (dev), PostgreSQL (production) |
| Styling | Tailwind CSS |
| Reactivity | Hotwire (Turbo + Stimulus) |
| Metadata API | TMDB |
| LLM | OpenAI API (GPT-4o or similar) |
| HTTP client | HTTParty |
| Asset pipeline | Propshaft |
| Telegram | Telegram Bot API |
| Auth | HTTP Basic Auth (env-configured) |

---

## 11. Integrations

### 11.1 TMDB API
- Used for: title lookup, metadata fetch, poster images, trailer links
- Rate limits: 40 requests/10 seconds (sufficient for single-user)
- API key stored in `.env`

### 11.2 OpenAI API (LLM)
- Used for: natural language title resolution, link content parsing
- Model: GPT-4o (configurable)
- API key stored in `.env`
- Invoked only when standard TMDB search fails or input is clearly descriptive

### 11.3 Telegram Bot API
- Used for: mobile capture via bot
- Webhook-based (not polling)
- Secret token validated on all incoming requests

---

## 12. Data Model (v1)

### `watchlist_items`
| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| title | string | Required |
| item_type | string | "movie" or "tv_show" |
| status | string | "want_to_watch" or "watched" |
| tmdb_id | integer | TMDB identifier |
| poster_url | string | |
| backdrop_url | string | |
| synopsis | text | |
| genres | string | Comma-separated |
| release_year | integer | |
| runtime_minutes | integer | Movies |
| episode_count | integer | TV shows |
| seasons_count | integer | TV shows |
| tmdb_rating | decimal | |
| streaming_service | string | e.g. "Netflix" |
| streaming_url | string | Direct link |
| trailer_url | string | YouTube link |
| official_website | string | |
| notes | text | User notes |
| added_at | datetime | |
| watched_at | datetime | |
| created_at | datetime | |
| updated_at | datetime | |

---

## 13. Milestones

| Milestone | Scope | Target |
|---|---|---|
| **M1 — Core list** | Add by URL + TMDB lookup, card UI, status toggle | Week 1–2 |
| **M2 — Title search** | TMDB search in web UI, manual add fallback | Week 2–3 |
| **M3 — LLM search** | Natural language resolution, link parsing | Week 3–4 |
| **M4 — Telegram** | Bot capture with all input types | Week 4–5 |
| **M5 — Polish** | Filtering, sorting, detail view, trailer embed | Week 5–6 |

---

## 14. Open Questions

1. **Streaming availability:** Do we want to show all platforms where an item is available (JustWatch API), or only capture what the user tells us at add time? v1 is capture-only; availability is a future feature.

2. **Multiple users / households:** v1 is single-user. If two people in a household want separate lists, they'd need separate deployments. Is a simple multi-user mode (username per item) worth adding in v1?

3. **Episode-level tracking:** TV show tracking is at the show level in v1. Should we support "watched through S2E6" style tracking? This adds significant complexity and is left for a future version.

4. **Offline / PWA:** Should the web UI work offline (PWA with service worker)? The Telegram bot covers mobile capture; PWA is low priority for v1.

5. **LLM cost management:** LLM calls are only triggered on fuzzy input. Should there be a configurable toggle to disable LLM features for cost control?

---

## 15. Success Metrics

This is a personal tool, not a growth product. Success looks like:

- Items get added without friction (under 10 seconds for URL, under 30 for natural language)
- The list accurately reflects what the user wants to watch — nothing missing, nothing stale
- Search returns the right thing on the first or second try
- The user stops maintaining a notes app, a sticky note, or a browser bookmark folder as their watchlist

---

*This document is the source of truth for Watchlist v1. Scope changes should be reflected here before implementation begins.*
