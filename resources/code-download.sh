#! /usr/bin/env sh

# Download code locally for local Docker testing
# usage: ./bin/code-download

mkdir -p code/repos
mkdir -p code/dirs


set pallets/flask \
    gorilla/mux \
    sinatra/sinatra \
    vuejs/vue \
    django/django \
    facebook/react \
    googleapis/gapic-generator

cd code/dirs
for project do 
    wget https://github.com/${project}/archive/master.zip
    unzip -o master.zip
    rm -f master.zip
done
cd ../../

cd code/repos
for project do 
    git clone --depth 1 https://github.com/${project}.git
done
cd ../../
