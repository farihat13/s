#!/bin/bash
set -ex

cd ~
wget https://farihat13.github.io/s/bashrc -O .bashrc
wget https://farihat13.github.io/s/vimrc -O .vimrc
wget https://farihat13.github.io/s/tmux.conf -O .tmux.conf

mkdir ~/scripts
cd ~/scripts
wget https://farihat13.github.io/s/system-info.sh
wget https://farihat13.github.io/s/mount-disk.sh
wget https://farihat13.github.io/s/unmount-disk.sh
chmod u+x ./*

sudo apt update
sudo apt install xclip

