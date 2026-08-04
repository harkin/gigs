# gigs

Rails app scraping Dublin music venues into a gig listing site.

## This repo is public
Commit messages, PR titles/bodies and anything under `docs/` are world-readable
and effectively permanent — edits don't erase forks, clones or notification mail.

Don't put infrastructure specifics in them: hosting or database **providers**,
**pricing tiers**, hostnames, public IPs, or region/endpoint identifiers. Keep
the reasoning, drop the vendor — "the database is remote, so every query costs a
round-trip" carries the same engineering weight as naming the two clouds and
what they cost. Measurements, timings and payload sizes are fine.

Config that already names a provider stays as is; this is about not adding new
detail in prose.

## Deploy
- Push to `main` → CI tests + kamal-deploys (`.github/workflows/deploy.yml`). No PR needed
- After deploying scraper changes, hit `GET /refresh` once (refreshes in a background thread, ~30s) or data stays stale.

## Databases
- dev/prod → remote PlanetScale (MySQL 8.4) on separate branches, so dev writes don't touch production. `bin/rails server` needs **no local DB**.
- test → local MySQL 8.4 on `localhost:3306` (db `gigs_test`, user `root`, no password). CI uses a `mysql:8.4` service.
- Per-environment credentials (`config/credentials/<env>.key`, no `master.key`). `development.key` is present so dev reaches PlanetScale; `production.key` isn't here (it's the deploy's `RAILS_MASTER_KEY`).

## Scraping (`app/lib/data_grabbers/`)
- One class per venue with `get_events`; `RefreshGigData` runs them in sequence and is intentionally **fail-loud** (one venue raising aborts the whole refresh). Don't add per-venue rescue without being asked.
- Prefer a structured JSON source (an API the page calls, or `__NEXT_DATA__`) over scraping rendered HTML. e.g. `academy.rb` hits the VenueCloud API directly.
- To test a grabber's parsing in isolation, stub `Event` + `ActiveRecord::Base.transaction` and run just fetch+parse in a throwaway script.
