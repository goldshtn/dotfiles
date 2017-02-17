#!/bin/bash

pushd $(dirname $0)
cp .bashrc ~/.bashrc
cp .vimrc ~/.vimrc
cp .inputrc ~/.inputrc
cp .screenrc ~/.screenrc
popd
