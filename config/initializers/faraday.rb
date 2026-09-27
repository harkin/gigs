# Scrapers call Faraday.get, which uses these defaults. Without them a venue
# that stops responding hangs the whole refresh.
Faraday.default_connection_options.request.open_timeout = 10
Faraday.default_connection_options.request.timeout = 30
