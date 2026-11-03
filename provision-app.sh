#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt-get install -y curl unzip

unzip nodejs20-sparta-tictactoe-v1.zip

cd app

npm start