#! /usr/bin/env sh

# Download repos to shared volume prior to starting src-expose container

source /app/bin/repos-list.sh

for project do 
    echo [info]: cloning ${project}
    git clone --depth 1 https://github.com/${project}.git
done
