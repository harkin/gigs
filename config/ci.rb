# The single source of truth for what "passing" means. Run with `bin/ci`,
# locally or in CI (.github/workflows/deploy.yml calls this before deploying).
# Steps run in order and stop on the first failure.

CI.run do
  step "Setup: dependencies", "bundle check || bundle install"

  # Tests use the local MySQL test database; dev/prod point at remote
  # PlanetScale, so DB steps must pin RAILS_ENV=test.
  step "Setup: test database", "env RAILS_ENV=test bin/rails db:prepare"

  # The index view references the compiled Tailwind asset, so build it or the
  # controller test 500s on the missing stylesheet.
  step "Assets: build Tailwind", "bin/rails tailwindcss:build"

  step "Security: importmap audit", "bin/importmap audit"

  step "Tests: Rails", "bin/rails test"
end
