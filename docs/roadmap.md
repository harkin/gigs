# Roadmap & TODOs

A living backlog to pick away at. Two main thrusts right now:

1. **Cover more Dublin venues** — add scrapers.
2. **Enrich the data we already pull** — ticket status, price, info links.

Standing infra/quality items are at the bottom.

---

## How to add a venue scraper

1. **Investigate the source first.** Prefer a structured JSON source (an API the
   page calls, or `__NEXT_DATA__`) over scraping rendered HTML — it's sturdier
   and doesn't break on markup tweaks. Many venues share a ticketing backend
   (Ticketmaster, Ticketsolve, Eventbrite, DICE), so one adapter can cover
   several.
2. Add the venue to the `Event` `venue` enum. Values so far run 0–6, so assign
   the **next free integer (7+)** — don't reuse or renumber existing ones.
3. Add a `renderable_venue` mapping in `Event`.
4. Write `app/lib/data_grabbers/<venue>.rb` with `self.get_events` that builds the
   events array, calls `EventValidator.validate!(events, venue: :<venue>)`, then
   does the `delete_all`/`insert_all` transaction.
5. Register it in `RefreshGigData.refresh_events`.
6. Dry-run it before wiring in: stub `Event` + `ActiveRecord::Base.transaction`
   and run just fetch+parse against the live page.

---

## 1. New venue scrapers

### Already stubbed in the enum (commented out)
- [x] Bord Gáis Energy Theatre — listing page (title, date range, price, per-show
      Ticketmaster link); status `available` while a buy button is shown.
- [x] The Grand Social — Wix Events query API (title, start datetime, slug →
      detail page); no ticket/price fields exposed, so status `unknown`.
- [x] National Concert Hall — paginated listing (title, date+time, detail page,
      tickets.nch.ie buy link); status available/sold-out. No price on the listing.
- [x] Pavilion Theatre (Dún Laoghaire) — via the shared **Ticketsolve** adapter
      (`shows.xml` feed): one Event per show at its next upcoming performance,
      status available/sold-out. Reusable for any Ticketsolve box office.
- [~] Pepper Canister Church — parked (see below)
- [~] Opium — parked (see below)

### Parked (scouted, not currently viable)
Each was investigated; none can be added cleanly today. A venue with **no
upcoming events** can't be wired in — `EventValidator` (min_count ≥ 1) would
raise and abort the whole fail-loud refresh.

- [~] The Sugar Club — **bot-blocked.** Tickets run through Ticket Tailor
      (Cloudflare-walled, 403). Their `/tickets` page server-renders only the
      soonest ~10 events; the rest load via an `admin-ajax` `load_more_events`
      proxy that's nonce-gated and rejects programmatic replay (`-1`). Needs a
      headless browser or the venue's Ticket Tailor API key.
- [~] Opium — Cloudflare 403 to scrapers.
- [~] Liberty Hall Theatre — **dormant.** WordPress + Events Manager (clean iCal
      feed at `/events/?ical=1`), but the latest event is May 2025 — no upcoming
      events. Revisit if it reprograms; the iCal makes it a quick add when active.
- [~] Arthur's — uses Wix Events (would drop into the WixEvents adapter) but has
      **0 upcoming events** scheduled; promotes via Eventbrite/Instagram instead.
- [~] Lost Lane / The Sound House — stale Tickera (`tc_events`) WordPress; the
      listing is JS-rendered with no structured event dates (same dead end as
      Whelan's `tc_events`), and Lost Lane punts to Eventbrite.
- [~] Fibber Magees — Joomla listing mixes recurring bar notices ("Open Till
      Late!", "LIVE MUSIC") with gigs, no ticket links, no year on dates. Too
      noisy for the integrity bar.
- [~] Wigwam — Squarespace, but "what's on" is recurring club nights (bingo,
      karaoke, trivia), not a ticketed gig calendar.
- [~] The Cobblestone — Squarespace with no events collection (trad sessions,
      largely unticketed).
- [~] Pepper Canister Church (domain 410 gone) / The National Stadium (no site)
      / Round Room at the Mansion House (civic venue, no public gig listing).

### Additional Dublin venues to add

**Mid-size / club:**
- [x] The Workman's Club — server-rendered listing (title, date+time, price,
      Eventbrite/promoter buy link, detail page); status available/sold-out.
- [~] Lost Lane / The Sound House / Wigwam / Fibber Magees / The Cobblestone /
      Arthur's — parked (see below)
- [ ] Bello Bar — domain not resolving; find current site
- [ ] Anseo — site has no obvious ticketing/listing platform; needs a closer look

**Theatres / concert halls:**
- [x] The Gaiety Theatre — server-rendered programme (title, run start date,
      detail page, Ticketmaster buy link); status `available`. No price on listing.
- [~] Liberty Hall Theatre — parked, dormant (see above)
- [x] The Helix (DCU) — via the shared **WixEvents** adapter (same Wix Events
      API as The Grand Social); title + datetime + detail page, status unknown.
- [~] The Round Room / The National Stadium — parked (see above)

**Stadiums / outdoor** — promoter-driven; no usable per-venue listing sites.
Best path is a single **Ticketmaster Discovery API** adapter keyed by venue
(covers all of the below at once). Needs a free API key from
developer.ticketmaster.com — the API returns 401 without one. This is the
highest-value remaining venue work, but it's blocked on that key.
- [ ] Croke Park
- [ ] Aviva Stadium
- [ ] Marlay Park
- [ ] St Anne's Park
- [ ] Royal Hospital Kilmainham (RHK)
- [ ] Iveagh Gardens
- [ ] Malahide Castle

---

## 2. Data enrichment

Current per-venue field coverage (✓ reliable · ◑ partial · ✗ missing):

| Venue | ticket_status | price | buy link | info link |
|---|---|---|---|---|
| The Academy | ◑ no "limited" tier | ✓ | ✓ | ✓ |
| Bord Gáis | ◑ available only | ✓ | ✓ | ✓ |
| Button Factory | ✗ always unknown | ✗ | ✗ | ✓ |
| The Gaiety | ◑ available only | ✗ | ✓ | ✓ |
| The Grand Social | ✗ always unknown | ✗ | ✗ | ✓ |
| The Helix | ✗ always unknown | ✗ | ✗ | ✓ |
| National Concert Hall | ◑ available/sold-out only | ✗ | ✓ | ✓ |
| The Olympia | ✓ | ✓ | ✓ | ✓ |
| O'Reilly Theatre | ◑ provider-dependent | ◑ Fever/Eventbrite only | ✓ | ✓ |
| Pavilion Theatre | ◑ available/sold-out only | ✗ | ✓ | ✓ |
| 3Arena (Point) | ✓ | ✗ | ✓ | ✓ |
| Vicar Street | ◑ available/sold-out only | ✗ | ✓ | ✓ |
| Whelan's | ✓ | ✓ | ✓ | ✓ |
| Workman's Club | ◑ available/sold-out only | ✓ | ◑ ticketed only | ✓ |

### TODOs
- [x] **Whelan's ticket_status** — derived from the WooCommerce Store API (one
      batched lookup by ticket slug → available / limited / sold-out).
- [ ] **Button Factory price + status** — the shows page carries neither; likely
      need to follow each show's detail page or its ticketing provider.
- [ ] **Vicar Street price** — not captured; check the listing markup / detail
      page for a price field.
- [ ] **O'Reilly Theatre price** — only Fever/Eventbrite events return one; the
      Ticketsolve and GK paths return `nil`. See if Ticketsolve exposes pricing.
- [x] **The Academy info link** — the venue has no per-event page, so `more_info`
      points at the Ticketmaster listing (the only detail URL). Cards layout also
      falls back to the ticket link for non-available events.
- [ ] **3Arena price** — not captured (secondary; arena prices are often ranges).
- [ ] **"Limited availability" tier** — Academy and Vicar Street only emit
      available/sold-out; map a middle tier where the source supports it.

---

## 3. Features
- [ ] Filter by event type (music / comedy / theatre / …) — needs a category
      field on `Event`, scraper support, and a filter UI control.
- [x] Mobile design — responsive layouts + themes shipped.
- [x] Show ticket prices — `price-tag` rendering shipped (per-venue gaps above).

---

## 4. Scraping architecture (future)

These two are coupled — incremental updates are what make richer enrichment
affordable without hammering third parties.

### Incremental upsert instead of delete-all + insert-all
Each grabber currently wipes its venue's rows (`delete_all`) and re-inserts the
whole list every refresh. Move to an upsert keyed on a stable per-event identity
(a venue event id where the source exposes one, else `(venue, title,
event_date)`), then prune only the rows no longer seen this run. Benefits:
- Stable primary keys / `created_at`; far less write churn.
- Lets us tell *new* events from ones we've already enriched — the enabler below.

Needs: a unique index on the chosen key (migration) + `upsert_all`, and a "seen
this run" set per venue to drive deletions.

### Careful, rate-limited enrichment
Some enrichment (e.g. prices) may mean visiting a provider — Ticketmaster,
Ticketsolve — *per event*. Done naively on every refresh that's a request storm
and a fast route to rate-limiting / being blocked. Guardrails:
- **Fetch once, persist.** Only enrich events missing the field; with the upsert
  model that means *new* events only, not the whole list each run.
- **Prefer official/bulk APIs** (e.g. Ticketmaster Discovery API with a key) over
  scraping per-event pages.
- **Throttle:** cap concurrency, add delays, honour `Retry-After` / 429 backoff,
  send a real User-Agent.
- Consider a separate, slower enrichment pass decoupled from the daily refresh
  rather than running it inline.

---

## 5. Standing infra / quality
- [ ] Scraper parser tests against recorded fixtures — see `docs/testing-plan.md`.
- [ ] CI secrets hardening — GHCR+OIDC or a kamal secrets adapter.
- [ ] Refresh heartbeat / dead-man's-switch — catch "the workflow silently
      stopped running".
- [ ] Tune `EventValidator` `min_count` per venue (all currently default to 1).
