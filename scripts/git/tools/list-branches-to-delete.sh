#!/usr/bin/env bash


git fetch origin;

#git branch --contains "$(git rev-parse "remotes/origin/dev")"


#git branch | tr -d ' *' | while read branch; do
#     echo "$branch";
#done


git branch --merged "remotes/origin/dev"
