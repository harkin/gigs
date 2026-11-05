# The single source of truth for what "passing" means. Run with `bin/ci`,
# locally or in CI (.github/workflows/test.yml, which also gates deploys).
# Steps run in order and stop on the first failure.

CI.run do
  step "Setup: dependencies", "bundle check || bundle install"

  # DB steps must pin RAILS_ENV=test so they don't touch the development database.
  step "Setup: test database", "env RAILS_ENV=test bin/rails db:prepare"

  step "Style: Ruby", "bin/rubocop"

  step "Security: gem audit", "bin/bundler-audit"
  step "Security: importmap audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: Rails", "bin/rails test"
end
