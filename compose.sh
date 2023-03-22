#!/bin/bash

# Get the current user and group IDs
uid=$(id -u)
gid=$(id -g)
user=$(id -un)

# Replace the placeholders in the Docker Compose YAML file
sed -e "s/{{UID}}/$uid/g" -e "s/{{GID}}/$gid/g" -e "s/{{USER}}/$user/g" docker-compose.yml.template > docker-compose.yml

# Run the docker-compose command
docker compose up -d --build

