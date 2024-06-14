#!/bin/zsh

set -e

echo "Downloading Miniconda installing script"
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

echo "Start installing Miniconda"
bash ./Miniconda3-latest-Linux-x86_64.sh -b

echo "Initializing Miniconda"
~/miniconda3/bin/conda init zsh
source ~/.zshrc

echo "Deleting downloaded script"
rm Miniconda3-latest-Linux-x86_64.sh
