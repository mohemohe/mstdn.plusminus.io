#!/bin/bash

docker node ls | grep Down | awk '{print $1}' | xargs docker node rm
