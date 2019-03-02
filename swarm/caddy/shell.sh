#!/bin/bash

docker exec -it $(docker ps | grep caddy | head -1 | awk '{print $1}') /bin/sh
