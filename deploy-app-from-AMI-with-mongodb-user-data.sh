#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

cd /home/ubuntu/tech613-tictactoe-node-app/app
export MONGODB_URI="mongodb://172.31.59.108:27017/tictactoe"
npm install
pm2 start index.js —name tictactoe