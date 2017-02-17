#!/bin/bash

pushd $(dirname)
cp .bashrc ~/.bashrc
cp .vimrc ~/.vimrc
cp .inputrc ~/.inputrc
cp .screenrc ~/.screenrc
popd
