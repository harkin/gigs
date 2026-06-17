# Ticketmaster Discovery API — setup plan

Goal: a reusable `DataGrabbers::TicketmasterDiscovery` adapter (like the
Ticketsolve / WixEvents adapters) that covers the promoter-driven stadium /
outdoor venues, which have no usable per-venue listing sites. One adapter,
queried per `venueId`, covers all of them — plus richer data (exact times,
sold-out/limited status, price ranges) than scraping.

This is blocked only on a (free) API key. Steps below.

---

## Part A — what you need to do

### 1. Get a Discovery API key (~5 min, free)
1. Go to **developer.ticketmaster.com** and sign up / sign in.
2. You'll land on **My Apps** with a default app already created.
3. Copy the **Consumer Key** — that's the `apikey`. (Ignore the Consumer Secret;
   the Discovery API only needs the key.)
4. Default quota: **5,000 calls/day at 5 req/sec**. Our daily refresh makes ~8
   calls, so quota is a non-issue.

### 2. Make the key available to the app

Pick one mechanism. Either way the code reads
`Rails.application.credentials.ticketmaster_api_key` (Option B) or
`ENV["TICKETMASTER_API_KEY"]` (Option A) — confirm which.

**Option B — Rails encrypted credentials (your preference).**
You add it yourself; the production master key is never disclosed to anyone.

```bash
# development (development.key is in the repo)
bin/rails credentials:edit --environment development
#   add:  ticketmaster_api_key: YOUR_KEY

# production (needs the prod master key only while YOU run this)
RAILS_MASTER_KEY=$(your prod key) bin/rails credentials:edit --environment production
#   add:  ticketmaster_api_key: YOUR_KEY
```
Commit the re-encrypted `development.yml.enc` and `production.yml.enc`. Because
`development.key` is in the repo, the dev copy lets the adapter be dry-run
locally; `production.key` stays private. Just tell me the key name used.

**Option A — env var (mirrors the existing `RAILS_MASTER_KEY` flow).**
```bash
printf %s 'YOUR_KEY' | gh secret set TICKETMASTER_API_KEY   # no trailing newline
export TICKETMASTER_API_KEY=YOUR_KEY                          # local/dev
```
I then wire `.kamal/secrets` + `config/deploy.yml` to inject it into the
container (same pattern as `RAILS_MASTER_KEY`). No production master key needed.

---

## Part B — what I build once the key is in place

1. `DataGrabbers::TicketmasterDiscovery` — reusable adapter hitting
   `https://app.ticketmaster.com/discovery/v2/events.json?apikey=…&venueId=…`,
   mapping to title, exact date+time (Europe/Dublin), status
   (available / limited / sold-out from `dates.status` + ticket limits), price
   range (`priceRanges`), and the TM buy URL. Paginate via `page`/`size`;
   filter to upcoming. Behind `EventValidator`, fail-loud.
2. Resolve `venueId`s via the venue search endpoint
   (`/discovery/v2/venues.json?apikey=…&keyword=Croke Park&countryCode=IE`).
   Known so far: **The National Stadium = `198253`**.
3. Thin per-venue grabbers: Croke Park, Aviva Stadium, Marlay Park,
   St Anne's Park, Royal Hospital Kilmainham, Iveagh Gardens, Malahide Castle.
4. Dry-run each against the live API, then ship.
5. Follow-ups: migrate **The National Stadium** off its TM-slug parsing onto this
   adapter (real times/prices/status), and optionally enrich The Gaiety / Olympia
   (also Ticketmaster).

---

## Notes
- Rate limits are generous; still, the daily refresh queries one call per venue,
  so no throttling needed beyond normal sequencing.
- `EventValidator` guards against an empty/garbled response aborting good data.
- A venue with no upcoming Ticketmaster events would return zero and (by design)
  raise in the fail-loud refresh — so each new venue is only wired in after a
  dry-run confirms it currently has events.
