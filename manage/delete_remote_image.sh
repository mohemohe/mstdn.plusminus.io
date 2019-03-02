#!/bin/bash -xe

cd ../swarm/mastodon
docker-compose -f docker-compose.manage.yml run --rm web bundle exec bin/tootctl media remove --background
