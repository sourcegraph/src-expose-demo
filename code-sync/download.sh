#! /usr/bin/env sh

# Download repos to shared volume prior to starting src-expose container

source /app/bin/repos-list.sh

for project do 
    echo [info]: downloading ${project}
    wget -q https://github.com/${project}/archive/master.zip
    unzip -o master.zip
    rm -f master.zip
done
