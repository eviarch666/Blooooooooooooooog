#!/bin/bash

mkdir tmp
cd tmp || exit

curl -L https://github.com/jgm/pandoc/releases/download/3.7.0.2/pandoc-3.7.0.2-linux-amd64.tar.gz
tar -xzf pandoc-3.7.0.2-linux-amd64.tar.gz

mkdir bin

cp pandoc-3.7.0.2/bin/* bin/.
