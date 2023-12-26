#!/usr/bin/env sh
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rake assets:clean