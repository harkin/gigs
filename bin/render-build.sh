#!/usr/bin/env sh
# exit on error
set -o errexit

bundle install
puts "Pre-compiling assets"
./bin/rails assets:precompile
puts "Cleaning assets"
./bin/rails assets:clean