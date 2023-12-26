#!/usr/bin/env sh
# exit on error
set -o errexit

bundle install
./bin/rails assets:precompile
./bin/rails rake assets:clean