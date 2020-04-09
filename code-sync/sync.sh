#! /usr/bin/env sh

# Example Pod design with a code sync container, syncing code to a shared volume read by the
# src-expose container.

# Crude code sync every minute (downloading and extracting from GitHub code archives) to simulate
# syncing code from a non-git code host with checked out local code (no actual git repos)


sync() {
    source /app/bin/repos-list.sh

    for project do
        echo [info]: downloading ${project}
        wget -q https://github.com/${project}/archive/master.zip
        unzip -o master.zip
        rm -f master.zip
    done
}

while : 
do
    sleep 60
    echo [info]: starting code sync...
    sync
    echo [info]: code sync completed    
done
