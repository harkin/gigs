# gigs

A listing of upcoming gigs at Dublin music venues. A Rails app scrapes each
venue's website once a day and serves the combined listing as a single page.

## Stack

- Ruby (version in `.ruby-version`) and Rails 8
- MySQL 8.4, via Trilogy
- Hotwire (Turbo + Stimulus) with importmap, Tailwind CSS
- Deployed as a Docker image with Kamal

## Development

```sh
bin/setup   # install gems, prepare the test database, start the server
bin/dev     # start the server (also rebuilds Tailwind on change)
```

Development connects to a remote MySQL database whose credentials live in
`config/credentials/development.yml.enc`, so no local database is needed to run
the app. You'll need `config/credentials/development.key` to decrypt it.

## Tests

Tests use a local MySQL 8.4 on `localhost:3306` (database `gigs_test`, user
`root`, no password). For example:

```sh
podman run -d --name gigs-mysql -p 3306:3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:8.4
```

Then run the same checks CI does (lint, security scans and tests):

```sh
bin/ci
```

## Scrapers

Each venue has a class in `app/lib/data_grabbers/` with a `get_events` method.
`RefreshGigData` runs them all in turn and stops at the first venue that raises,
so a broken scraper shows up as a failed refresh rather than silently stale
data. Run a refresh with:

```sh
bin/rails gigs:refresh
```

`docs/roadmap.md` explains how to add a venue.

## Deployment

Pushing to `main` runs the tests and deploys with Kamal
(`.github/workflows/deploy.yml`). A scheduled workflow
(`.github/workflows/refresh.yml`) refreshes the gig data daily.
