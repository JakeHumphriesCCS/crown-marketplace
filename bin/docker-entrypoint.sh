#!/usr/bin/env bash

# remove the next lines:
bundle exec rails rails db:environment:set RAILS_ENV=production
bundle exec rails db:drop
bundle exec rails rails db:environment:set RAILS_ENV=production
bundle exec rails db:setup

bundle exec rails db:migrate

bundle exec rails db:static
bundle exec rails db:postcode

bundle exec sidekiq -C ./config/sidekiq.yml -d -L ./log/sidekiq.log -e production if ENV['APP_RUN_SIDEKIQ'].present?

bundle exec rails server
