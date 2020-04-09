#! /usr/bin/env sh

# Example Pod design with a code sync container, syncing git repositories to a 
# shared volume read by the src-expose container.

sync() {
    source /app/bin/repos-list.sh

    for repo in ./*;
    do 
        [ -d $repo ] && cd $repo && git pull && cd -
    done; 
}

while : 
do
    sleep 60
    echo [info]: starting code sync...
    sync
    echo [info]: code sync completed    
done
