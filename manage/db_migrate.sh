#!/bin/bash -xe

cd ../swarm/mastodon
docker-compose -f docker-compose.manage.yml pull
docker-compose -f docker-compose.manage.yml run --rm web rails db:migrate
