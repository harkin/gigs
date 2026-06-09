# Testing plan (future work)

**Current state (2026-06-09):** the suite has **one** real test — a homepage smoke
test (`test/controllers/gigs_controller_test.rb`) that does `get root_url` and
asserts a 2xx response, against an empty database. It verifies "the index renders
without raising" (routing → controller → two AR queries → views/layout → Propshaft
Tailwind asset → middleware) but asserts **nothing about content**, and the app's
core value — scraping gig data — is entirely untested.

CI now runs `bin/rails test` before deploying (MariaDB service container), so any
tests we add will gate the deploy.

## Priorities (highest value first)

1. **Scraping / import logic — the riskiest untested area.** `RefreshGigData`
   fetches venue pages (faraday) and parses them (nokogiri) into `Event` records.
   Test the parsers against **recorded HTML fixtures** (WebMock/VCR) so they run
   offline and deterministically. Cover each venue parser, malformed/blank pages,
   de-duplication, and date parsing. This is what actually breaks when a venue
   changes its markup.

2. **Index with data.** Add an `events` fixture and assert the page renders real
   events: the default `table` layout and `?layout=cards`, correct ordering by
   `event_date`, the `@last_refreshed_at` display, and the empty-state path.
   (Assert content, not just status.)

3. **Model tests.** `Event`: the `venues` enum, `renderable_venue`, any
   validations/scopes. `Refresh`: `last_refresh_at` behaviour.

4. **`refresh` action.** Assert it redirects to index and triggers a refresh. Note
   the controller currently spawns a raw `Thread` — worth testing the contract and
   probably revisiting that threading (e.g. a background job).

5. **System tests (optional, later).** Browser-driven (Capybara) for the
   Turbo/Stimulus layout switching, if it earns the maintenance cost.

## Infra notes

- Tests need MySQL on `localhost:3306` (db `gigs_test`, user `root`, empty
  password). Use **MySQL 8.4** to match production (PlanetScale runs MySQL 8.4).
  Locally: the `gigs-mysql` podman container. In CI: a `mysql:8.4` service
  container (already wired in `.github/workflows/deploy.yml`).
- The index view references the compiled Tailwind asset, so
  `bin/rails tailwindcss:build` must run before the suite (CI does this).
- The test environment needs **no** secrets / `RAILS_MASTER_KEY`.
- If `db:prepare` ever does heavy work in CI, review `db/seeds.rb`.
