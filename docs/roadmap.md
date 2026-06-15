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
- [ ] Pavilion Theatre (Dún Laoghaire)
- [ ] Pepper Canister Church
- [ ] Opium
- [ ] The Sugar Club

### Additional Dublin venues to add

**Mid-size / club:**
- [x] The Workman's Club — server-rendered listing (title, date+time, price,
      Eventbrite/promoter buy link, detail page); status available/sold-out.
- [ ] Lost Lane
- [ ] The Sound House
- [ ] Bello Bar
- [ ] Wigwam
- [ ] Fibber Magees
- [ ] The Cobblestone (trad)
- [ ] Arthur's
- [ ] Anseo

**Theatres / concert halls:**
- [ ] The Gaiety Theatre
- [ ] Liberty Hall Theatre
- [ ] The Helix (DCU)
- [ ] The Round Room (Mansion House)
- [ ] The National Stadium

**Stadiums / outdoor** — promoter-driven; may be better sourced via the promoter
(MCD / Live Nation / Ticketmaster) than per-venue sites:
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
| The Grand Social | ✗ always unknown | ✗ | ✗ | ✓ |
| National Concert Hall | ◑ available/sold-out only | ✗ | ✓ | ✓ |
| The Olympia | ✓ | ✓ | ✓ | ✓ |
| O'Reilly Theatre | ◑ provider-dependent | ◑ Fever/Eventbrite only | ✓ | ✓ |
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
