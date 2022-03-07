#!/usr/bin/env bash

#Copy files from _shared to all other folders
for folder in $(echo */)
do
  if [[ $folder != _* ]]; then
    echo "Copy files to ${folder}"
    cp _shared/* $folder
  fi
done