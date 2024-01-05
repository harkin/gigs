#!/usr/bin/env sh
# exit on error
set -o errexit

bundle install
echo "Pre-compiling assets"
./bin/rails assets:precompile
echo "Cleaning assets"
./bin/rails assets:clean
echo "Run migrations"
./bin/rails db:migrate