#!/bin/bash

curl -LO https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.deb
sudo apt install ./yazi-x86_64-unknown-linux-gnu.deb
rm yazi-x86_64-unknown-linux-gnu.deb
